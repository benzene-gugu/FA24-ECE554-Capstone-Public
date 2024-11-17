#include "flash.h"

#include "spi.h"
#include "printf.h"

uint32_t flash_read_id()
{
    static uint8_t tx[4] = {0x9f, 0x00, 0x00, 0x00};
    uint8_t rx[4];

    spi_set_ss(1);
    spi_transfer(tx, rx, 4);
    spi_set_ss(0);

    // printf("%x %x %x\r\n", rx[1], rx[2], rx[3]);

    return rx[1] << 16 | rx[2] << 8 | rx[3];
}

void flash_read_data(uint8_t *dst, uint32_t flash_addr, uint32_t size)
{
    static uint8_t tx[SPI_BUFFER_SIZE] = {0};
    uint32_t transfer_size = size + 4;

    if (transfer_size > SPI_BUFFER_SIZE)
    {
        printf("Too large of a flash read.\r\n");
        return;
    }

    tx[0] = 0x03;
    tx[1] = (flash_addr >> 16) & 0xff;
    tx[2] = (flash_addr >> 8) & 0xff;
    tx[3] = flash_addr & 0xff;

    spi_set_ss(1);

    while (spi_is_busy())
    {
    }

    if (spi_tx_entries() != 0)
    {
        printf("SPI TX num entries not 0! Got %d expected %x\r\n", spi_tx_entries(), 0);
    }

    for (uint32_t i = 0; i < transfer_size; i++)
    {
        SPI_TX_REG = tx[i];
    }

    if (spi_tx_entries() != transfer_size)
    {
        printf("SPI TX num entries mismatch! Got %d expected %x\r\n", spi_tx_entries(), transfer_size);
    }

    spi_set_transmit(true);

    while (spi_is_busy())
    {
    }

    spi_set_transmit(false);

    if (spi_rx_entries() != transfer_size)
    {
        printf("SPI RX num entries mismatch! Got %d expected %x\r\n", spi_rx_entries(), transfer_size);
    }

    for (uint32_t i = 0; i < 4; i++)
    {
        dst[0] = SPI_RX_REG;
    }

    for (uint32_t i = 0; i < size; i++)
    {
        dst[i] = SPI_RX_REG;
    }

    if (spi_rx_entries() != 0)
    {
        printf("SPI RX num entries not 0! Got %d expected %x\r\n", spi_rx_entries(), 0);
    }

    spi_set_ss(0);
}
