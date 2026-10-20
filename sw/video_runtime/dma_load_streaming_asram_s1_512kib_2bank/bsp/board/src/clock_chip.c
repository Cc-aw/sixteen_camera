#include "clock_chip.h"

#include <stddef.h>
#include <stdint.h>

#include "axi_iic.h"
#include "mmio.h"
#include "platform.h"

/*
 * Fixed synthesizer-mode table from the FMC HDMI reference demo's
 * idt_8t49n24x.h. It generates a free-running 148.5 MHz clock on Q2/Q3.
 * Keeping a fixed integer table avoids floating-point clock calculations on
 * the RV64 core and gives the first 1080p60 bring-up a deterministic clock.
 */
static const uint8_t config_148p5[] = {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xEF, 0x00,
    0x03, 0x00, 0x31, 0x00, 0x04, 0x89, 0x00, 0x00,
    0x01, 0x00, 0x63, 0xC6, 0x07, 0x00, 0x00, 0x77,
    0x6D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF,
    0xFF, 0xFF, 0xFF, 0x01, 0x3F, 0x00, 0x28, 0x00,
    0x1A, 0xCC, 0xCD, 0x00, 0x01, 0x00, 0x00, 0xD0,
    0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00,
    0x00, 0x0C, 0x00, 0x00, 0x00, 0x44, 0x44, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0B,
    0x00, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x89, 0x0A, 0x2B, 0x20, 0x00, 0x00, 0x00, 0x03,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x27, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00
};

/*
 * Jitter-attenuator table from the FMC HDMI reference driver.  The VPHY
 * forwards the 148.5 MHz RX TMDS clock to input 0; Q2/Q3 then remain at
 * 148.5 MHz while frequency-locked to the source.  That lock is required to
 * prevent long-term FIFO drift in the DDR-less streaming pipeline.
 */
static const uint8_t config_148p5_locked[] = {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFE, 0xEF, 0x00,
    0x03, 0x00, 0x20, 0x00, 0x04, 0x89, 0x00, 0x00,
    0x01, 0x00, 0x63, 0xC6, 0x07, 0x00, 0x00, 0x77,
    0x6D, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF,
    0xFF, 0xFF, 0xFF, 0x01, 0x3F, 0x00, 0x28, 0x00,
    0x1A, 0xCC, 0xCD, 0x00, 0x01, 0x00, 0x00, 0xD0,
    0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x00,
    0x00, 0x0C, 0x00, 0x00, 0x00, 0x44, 0x44, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0B,
    0x00, 0x00, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x89, 0x02, 0x2B, 0x20, 0x00, 0x00, 0x00, 0x03,
    0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x27, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00
};

static void delay_us(uint32_t microseconds)
{
    uint64_t cycles = ((uint64_t)SOC_CLOCK_HZ * microseconds) / 1000000U;
    uint64_t until = read_cycle() + cycles;
    while ((int64_t)(read_cycle() - until) < 0) {
    }
}

static int write_register(uint16_t reg, uint8_t value)
{
    uint8_t message[3] = {
        (uint8_t)(reg >> 8),
        (uint8_t)reg,
        value
    };
    /* Return the AXI IIC to a known idle state for every device access. */
    axi_iic_init();
    int result = axi_iic_write(HDMI_CLK_I2C_ADDRESS, message,
                               sizeof(message));
    delay_us(500U);
    return result == AXI_IIC_OK ? CLOCK_CHIP_OK : CLOCK_CHIP_IIC_ERROR;
}

static int read_register(uint16_t reg, uint8_t *value)
{
    uint8_t address[2] = {(uint8_t)(reg >> 8), (uint8_t)reg};
    /* Dynamic-mode reads leave status bits latched; reset before the next. */
    axi_iic_init();
    int result = axi_iic_write_read(HDMI_CLK_I2C_ADDRESS, address,
                                    sizeof(address), value, 1U);
    return result == AXI_IIC_OK ? CLOCK_CHIP_OK : CLOCK_CHIP_IIC_ERROR;
}

static int modify_register(uint16_t reg, uint8_t value, uint8_t mask)
{
    uint8_t old_value;
    if (read_register(reg, &old_value) != CLOCK_CHIP_OK) {
        return CLOCK_CHIP_IIC_ERROR;
    }
    return write_register(reg, (uint8_t)((old_value & (uint8_t)~mask) |
                                          (value & mask)));
}

int clock_chip_read_id(uint16_t *device_id)
{
    uint8_t address[2] = {0x00U, 0x02U};
    uint8_t id_registers[3] = {0xFFU, 0xFFU, 0xFFU};
    if (device_id == NULL) {
        return CLOCK_CHIP_IIC_ERROR;
    }

    /* Read the consecutive ID registers in one repeated-start transaction. */
    axi_iic_init();
    if (axi_iic_write_read(HDMI_CLK_I2C_ADDRESS, address, sizeof(address),
                           id_registers, sizeof(id_registers)) != AXI_IIC_OK) {
        return CLOCK_CHIP_IIC_ERROR;
    }

    *device_id = (uint16_t)((((uint16_t)id_registers[0] & 0x0FU) << 12) |
                            ((uint16_t)id_registers[1] << 4) |
                            ((uint16_t)id_registers[2] >> 4));
    return ((*device_id == 0x0606U) || (*device_id == 0x0607U))
               ? CLOCK_CHIP_OK
               : CLOCK_CHIP_BAD_ID;
}

static int program_table(const uint8_t *table, size_t table_size)
{
    uint16_t device_id;
    int result = clock_chip_read_id(&device_id);
    if (result != CLOCK_CHIP_OK) {
        return result;
    }

    /* Disable DPLL and APLL calibration while updating their parameters. */
    if (modify_register(0x0070U, 0x05U, 0x05U) != CLOCK_CHIP_OK) {
        return CLOCK_CHIP_IIC_ERROR;
    }

    for (size_t reg = 8U; reg < table_size; ++reg) {
        /* 0x70 is enabled only after all other settings are stable. */
        if ((reg != 0x70U) &&
            (write_register((uint16_t)reg, table[reg]) !=
             CLOCK_CHIP_OK)) {
            return CLOCK_CHIP_IIC_ERROR;
        }
    }

    /* Enable the DPLL and APLL calibration logic. */
    return modify_register(0x0070U, 0x00U, 0x05U);
}

static int select_mode(const uint8_t *table)
{
    static const uint8_t mode_registers[] = {0x0AU, 0x69U, 0x73U};
    uint16_t device_id;
    int result = clock_chip_read_id(&device_id);
    if (result != CLOCK_CHIP_OK)
        return result;

    if (modify_register(0x0070U, 0x05U, 0x05U) != CLOCK_CHIP_OK)
        return CLOCK_CHIP_IIC_ERROR;
    for (size_t index = 0U; index < sizeof(mode_registers); ++index) {
        uint8_t reg = mode_registers[index];
        if (write_register(reg, table[reg]) != CLOCK_CHIP_OK)
            return CLOCK_CHIP_IIC_ERROR;
    }
    return modify_register(0x0070U, 0x00U, 0x05U);
}

int clock_chip_program_148p5(void)
{
    return program_table(config_148p5, sizeof(config_148p5));
}

int clock_chip_program_148p5_locked(void)
{
    return select_mode(config_148p5_locked);
}

int clock_chip_select_148p5_free_running(void)
{
    return select_mode(config_148p5);
}
