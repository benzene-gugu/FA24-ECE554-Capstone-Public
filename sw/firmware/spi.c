#include "spi.h"
#include "../inc/memmap.h"
#include <stdbool.h>

__attribute__((__section__(".bootrom")))
void spi_set_ss(bool ss)
{
    spi_control_reg_t control;

    control.word = SPI_CONTROL_REG;

    control.SS_n = !ss;

    SPI_CONTROL_REG = control.word;
}
__attribute__((__section__(".bootrom")))
bool spi_is_busy()
{
    spi_status_reg_t status;

    status.word = SPI_STATUS_REG;

    return status.busy;
}
__attribute__((__section__(".bootrom")))
uint32_t spi_rx_entries()
{
    spi_status_reg_t status;

    status.word = SPI_STATUS_REG;

    return status.rx_queue_num_entries;
}
__attribute__((__section__(".bootrom")))
uint32_t spi_tx_entries()
{
    spi_status_reg_t status;

    status.word = SPI_STATUS_REG;

    return status.tx_queue_num_entries;
}
__attribute__((__section__(".bootrom")))
void spi_set_transmit(bool transmit)
{
    spi_control_reg_t control;

    control.word = SPI_CONTROL_REG;

    control.transmit = transmit;

    SPI_CONTROL_REG = control.word;
}
__attribute__((__section__(".bootrom")))
void spi_transfer(uint8_t *tx, uint8_t *rx, uint32_t size)
{
    while (spi_is_busy())
    {
    }

    if (spi_tx_entries() != 0)
    {
        MMAP_LED = 1<<8;
    }

    for (uint32_t i = 0; i < size; i++)
    {
        SPI_TX_REG = tx[i];
    }

    if (spi_tx_entries() != size)
    {
        MMAP_LED = 1<<8;
    }

    spi_set_transmit(true);

    while (spi_is_busy())
    {
    }

    spi_set_transmit(false);

    if (spi_rx_entries() != size)
    {
        MMAP_LED = 1<<8;
    }

    for (uint32_t i = 0; i < size; i++)
    {
        rx[i] = SPI_RX_REG;
    }

    if (spi_rx_entries() != 0)
    {
        MMAP_LED = 1<<8;
    }
}
