#include "axi_iic.h"
#include "mmio.h"
#include "platform.h"

#define IIC_IISR       0x020U
#define IIC_RESETR     0x040U
#define IIC_CR         0x100U
#define IIC_SR         0x104U
#define IIC_DTR        0x108U
#define IIC_DRR        0x10CU
#define IIC_RFO        0x118U
#define IIC_RFD        0x120U

#define IIC_RESET      0x0AU
#define IIC_CR_ENABLE  0x01U
#define IIC_CR_TXRST   0x02U
#define IIC_SR_BUSY    0x04U
#define IIC_SR_RXEMPTY 0x40U
#define IIC_INTR_ARB    0x01U
#define IIC_INTR_TXERR 0x02U
#define IIC_INTR_BNB   0x10U
#define IIC_DYN_START  0x100U
#define IIC_DYN_STOP   0x200U
#define IIC_TIMEOUT    (SOC_CLOCK_HZ / 10U)

static int wait_bus_idle(void)
{
    for (uint32_t timeout = IIC_TIMEOUT; timeout != 0U; --timeout) {
        if ((mmio_read32(AXI_IIC_BASE + IIC_SR) & IIC_SR_BUSY) == 0U) {
            return AXI_IIC_OK;
        }
    }
    return AXI_IIC_TIMEOUT;
}

static int wait_rx_data(void)
{
    for (uint32_t timeout = IIC_TIMEOUT; timeout != 0U; --timeout) {
        if ((mmio_read32(AXI_IIC_BASE + IIC_SR) & IIC_SR_RXEMPTY) == 0U) {
            return AXI_IIC_OK;
        }
        /*
         * During a controller read, TXERR is latched for the expected final
         * NACK and BNB may become visible before the last RX FIFO state update.
         * Therefore only the FIFO state is authoritative while receiving.
         */
    }
    return AXI_IIC_TIMEOUT;
}

static int wait_transfer_done(void)
{
    for (uint32_t timeout = IIC_TIMEOUT; timeout != 0U; --timeout) {
        uint32_t status = mmio_read32(AXI_IIC_BASE + IIC_IISR);
        if ((status & IIC_INTR_BNB) != 0U) {
            mmio_write32(AXI_IIC_BASE + IIC_IISR, IIC_INTR_BNB);
            return AXI_IIC_OK;
        }
    }
    return AXI_IIC_TIMEOUT;
}

void axi_iic_init(void)
{
    mmio_write32(AXI_IIC_BASE + IIC_RESETR, IIC_RESET);
    mmio_write32(AXI_IIC_BASE + IIC_RFD, 0x0FU);
    mmio_write32(AXI_IIC_BASE + IIC_CR, IIC_CR_ENABLE | IIC_CR_TXRST);
    mmio_write32(AXI_IIC_BASE + IIC_CR, IIC_CR_ENABLE);
    mmio_write32(AXI_IIC_BASE + IIC_IISR, 0xFFFFFFFFU);
    mmio_fence();
}

int axi_iic_bus_busy(void)
{
    return (mmio_read32(AXI_IIC_BASE + IIC_SR) & IIC_SR_BUSY) != 0U;
}

int axi_iic_write(uint8_t address, const uint8_t *data, size_t length)
{
    if ((data == 0) || (length == 0U) || (length > 15U)) {
        return AXI_IIC_INVALID;
    }
    if (wait_bus_idle() != AXI_IIC_OK) {
        return AXI_IIC_TIMEOUT;
    }
    mmio_write32(AXI_IIC_BASE + IIC_IISR,
                 IIC_INTR_ARB | IIC_INTR_TXERR | IIC_INTR_BNB);

    mmio_write32(AXI_IIC_BASE + IIC_DTR,
                 IIC_DYN_START | ((uint32_t)address << 1));
    for (size_t index = 0U; index < length; ++index) {
        uint32_t value = data[index];
        if (index + 1U == length) {
            value |= IIC_DYN_STOP;
        }
        mmio_write32(AXI_IIC_BASE + IIC_DTR, value);
    }
    if (wait_transfer_done() != AXI_IIC_OK) {
        return AXI_IIC_TIMEOUT;
    }
    uint32_t status = mmio_read32(AXI_IIC_BASE + IIC_IISR);
    mmio_write32(AXI_IIC_BASE + IIC_IISR,
                 status & (IIC_INTR_ARB | IIC_INTR_TXERR));
    return (status & (IIC_INTR_ARB | IIC_INTR_TXERR)) != 0U
               ? AXI_IIC_NACK
               : AXI_IIC_OK;
}

int axi_iic_read(uint8_t address, uint8_t *data, size_t length)
{
    if ((data == 0) || (length == 0U) || (length > 255U)) {
        return AXI_IIC_INVALID;
    }
    if (wait_bus_idle() != AXI_IIC_OK) {
        return AXI_IIC_TIMEOUT;
    }
    mmio_write32(AXI_IIC_BASE + IIC_IISR,
                 IIC_INTR_ARB | IIC_INTR_TXERR | IIC_INTR_BNB);

    mmio_write32(AXI_IIC_BASE + IIC_DTR,
                 IIC_DYN_START | ((uint32_t)address << 1) | 1U);
    mmio_write32(AXI_IIC_BASE + IIC_DTR,
                 IIC_DYN_STOP | (uint32_t)length);

    for (size_t index = 0U; index < length; ++index) {
        int result = wait_rx_data();
        if (result != AXI_IIC_OK) {
            return result;
        }
        data[index] = (uint8_t)mmio_read32(AXI_IIC_BASE + IIC_DRR);
    }
    if (wait_transfer_done() != AXI_IIC_OK) {
        return AXI_IIC_TIMEOUT;
    }
    /* A controller NACK on the final read byte may latch TXERR normally. */
    uint32_t status = mmio_read32(AXI_IIC_BASE + IIC_IISR);
    mmio_write32(AXI_IIC_BASE + IIC_IISR,
                 status & (IIC_INTR_ARB | IIC_INTR_TXERR));
    return (status & IIC_INTR_ARB) != 0U ? AXI_IIC_NACK : AXI_IIC_OK;
}

int axi_iic_write_read(uint8_t address, const uint8_t *write_data,
                       size_t write_length, uint8_t *read_data,
                       size_t read_length)
{
    if ((write_data == 0) || (read_data == 0) ||
        (write_length == 0U) || (write_length > 13U) ||
        (read_length == 0U) || (read_length > 255U)) {
        return AXI_IIC_INVALID;
    }
    if (wait_bus_idle() != AXI_IIC_OK) {
        return AXI_IIC_TIMEOUT;
    }
    mmio_write32(AXI_IIC_BASE + IIC_IISR,
                 IIC_INTR_ARB | IIC_INTR_TXERR | IIC_INTR_BNB);

    /* Queue write address/data without STOP, then a repeated-start read. */
    mmio_write32(AXI_IIC_BASE + IIC_DTR,
                 IIC_DYN_START | ((uint32_t)address << 1));
    for (size_t index = 0U; index < write_length; ++index) {
        mmio_write32(AXI_IIC_BASE + IIC_DTR, write_data[index]);
    }
    mmio_write32(AXI_IIC_BASE + IIC_DTR,
                 IIC_DYN_START | ((uint32_t)address << 1) | 1U);
    mmio_write32(AXI_IIC_BASE + IIC_DTR,
                 IIC_DYN_STOP | (uint32_t)read_length);

    for (size_t index = 0U; index < read_length; ++index) {
        int result = wait_rx_data();
        if (result != AXI_IIC_OK) {
            return result;
        }
        read_data[index] = (uint8_t)mmio_read32(AXI_IIC_BASE + IIC_DRR);
    }
    if (wait_transfer_done() != AXI_IIC_OK) {
        return AXI_IIC_TIMEOUT;
    }

    uint32_t status = mmio_read32(AXI_IIC_BASE + IIC_IISR);
    mmio_write32(AXI_IIC_BASE + IIC_IISR,
                 status & (IIC_INTR_ARB | IIC_INTR_TXERR));
    return (status & IIC_INTR_ARB) != 0U ? AXI_IIC_NACK : AXI_IIC_OK;
}
