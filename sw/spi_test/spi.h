#pragma once

#include <stdint.h>
#include <stdbool.h>

typedef union
{
    struct
    {

        uint32_t clk_per_half_cycle : 8;
        uint32_t SS_n : 1;
        uint32_t transmit : 1;
        uint32_t reserved : 22;
    };
    uint32_t word;
} spi_control_reg_t;

typedef union
{
    struct
    {

        uint32_t rx_queue_num_entries : 13;
        uint32_t tx_queue_num_entries : 13;
        uint32_t busy : 1;
        uint32_t reserved : 5;
    };
    uint32_t word;
} spi_status_reg_t;

#define SPI_ADDR (0x11000000)

#define SPI_BUFFER_SIZE (4096)

#define SPI_CONTROL_REG (*(volatile uint32_t *)(SPI_ADDR + 0))
#define SPI_STATUS_REG (*(volatile uint32_t *)(SPI_ADDR + 4))
#define SPI_TX_REG (*(volatile uint32_t *)(SPI_ADDR + 8))
#define SPI_RX_REG (*(volatile uint32_t *)(SPI_ADDR + 12))

void spi_transfer(uint8_t *tx, uint8_t *rx, uint32_t size);
void spi_set_ss(bool ss);
