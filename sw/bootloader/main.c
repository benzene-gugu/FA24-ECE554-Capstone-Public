#include <stdint.h>

#include "spi.h"
#include "flash.h"
#include "printf.h"
#include "memmap.h"

#define APP_SIZE (16 * 1024 * 1024)
#define APP_ADDR ((uint8_t *)0)

typedef void (*app_start_t)();

char getc()
{
    while (GET_UART_RX_QLEN(MMAP_UART_CTRL) == 0)
        ;
    char input = MMAP_UART_QUEU;
    _putchar(input); // echo back
    return input;
}

__attribute__((__section__(".mainfun"))) void main()
{
    printf("Hello from SPI bootloader!\r\n");

    spi_control_reg_t control;
    control.word = SPI_CONTROL_REG;
    control.clk_per_half_cycle = 3;
    SPI_CONTROL_REG = control.word;

    for (uint32_t attempts = 0; attempts < 5; attempts++)
    {
        uint32_t flash_id = flash_read_id();

        if (flash_id == FLASH_EXPECTED_ID)
        {
            printf("Flash ID match.\r\n");
            break;
        }
        else
        {
            printf("Flash ID mismatch! Got %x expected %x.\r\n", flash_id, FLASH_EXPECTED_ID);
        }
    }

    printf("Reading %x bytes to %x from flash...\r\n", APP_SIZE, APP_ADDR);

    uint32_t left_to_read = APP_SIZE;
    uint8_t *app_addr = APP_ADDR;
    uint32_t flash_addr = 0;
    while (left_to_read > 0)
    {
        uint32_t chunk_size = SPI_BUFFER_SIZE - 4;
        if (chunk_size > left_to_read)
            chunk_size = left_to_read;

        flash_read_data(app_addr, flash_addr, chunk_size);

        // for (uint32_t i = 0; i < chunk_size; i++)
        // {
        //     if (i % 2 == 0)
        //     {
        //         if (app_addr[i] != 0xAA)
        //         {
        //             printf("Error at %x! Got %x\r\n", &app_addr[i], app_addr[i]);
        //         }
        //     }
        //     else
        //     {
        //         if (app_addr[i] != 0x55)
        //         {
        //             printf("Error at %x! Got %x\r\n", &app_addr[i], app_addr[i]);
        //         }
        //     }
        // }

        app_addr += chunk_size;
        flash_addr += chunk_size;
        left_to_read -= chunk_size;
    }

    printf("Finished reading flash.\r\n");

    app_start_t app_start = (app_start_t)APP_ADDR;

    printf("Jumping to %x.\r\n", app_start);

    app_start();

    for (;;)
    {
        printf("Returned from APP!\r\n");
    }
}
