#ifndef VIDEO_CTRL_AXI_IIC_H
#define VIDEO_CTRL_AXI_IIC_H

#include <stddef.h>
#include <stdint.h>

enum axi_iic_result {
    AXI_IIC_OK = 0,
    AXI_IIC_TIMEOUT = -1,
    AXI_IIC_NACK = -2,
    AXI_IIC_INVALID = -3
};

void axi_iic_init(void);
int axi_iic_bus_busy(void);
int axi_iic_write(uint8_t address, const uint8_t *data, size_t length);
int axi_iic_read(uint8_t address, uint8_t *data, size_t length);
int axi_iic_write_read(uint8_t address, const uint8_t *write_data,
                       size_t write_length, uint8_t *read_data,
                       size_t read_length);

#endif
