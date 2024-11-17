// #define PRINTF_DISABLE_SUPPORT_FLOAT
// #define PRINTF_DISABLE_SUPPORT_EXPONENTIAL
// #define PRINTF_DISABLE_SUPPORT_LONG_LONG 
// #include "printf.h"
#include <../inc/memmap.h>
#include "spi.h"
#include "../inc/consts.h"
#include "flash.h"

#define APP_SIZE (16 * 1024 * 1024)
#define APP_ADDR ((uint8_t *)0)

typedef void (*app_start_t)();

__attribute__((__section__(".bootrom")))
void memcpy(void *dest, void *src, int n)  
{
    //n /= 4;
    char *csrc = (char*)src;  
    char *cdest = (char*)dest;  
  
    for (int i=0; i<n; ++i)  
        cdest[i] = csrc[i];  
}

// int isprint(int c)
// {
// 	return ((c >= ' ' && c <= '~') ? 1 : 0);
// }

__attribute__((__section__(".bootrom")))
void _putchar(char character)
{
  while(GET_UART_TX_QREM(MMAP_UART_CTRL) == 0);
  MMAP_UART_QUEU = character;
}

__attribute__((__section__(".bootrom")))
char getc()
{
    while(GET_UART_RX_QLEN(MMAP_UART_CTRL) == 0);
    char input = MMAP_UART_QUEU;
    return input;
}

__attribute__((__section__(".bootrom")))
void get_word(int *dest)
{
    for(int i = 0; i < 4; ++i)
    {
        *dest <<= 8;
        *dest |= getc();
    }
}

__attribute__((__section__(".bootrom")))
void main()
{
    char in[16];
    int len, checksum, check_gen;
    char *start;
    int rescode = 0;
    char auto_mode;
    unsigned int clk, nclk;

    do
    {
        __clock(nclk);
    } while (nclk < CLK_FREQ);

    auto_mode = MMAP_HIN>>12;

    if(auto_mode == 0) //automatically read from spi flash
    {
        char err = 0;
        MMAP_LED = 1<<9;
        spi_control_reg_t control;
        control.word = SPI_CONTROL_REG;
        control.clk_per_half_cycle = 3;
        SPI_CONTROL_REG = control.word;
        //check flash ID
        for (uint32_t attempts = 0; attempts < 5; attempts++)
        {
            uint32_t flash_id = flash_read_id();

            if (flash_id == FLASH_EXPECTED_ID)
            {
                MMAP_LED = 1<<9;
                err = 0;
                break;
            }
            else
            {
                MMAP_LED = 1<<8;
                err = 1;
            }
        }
        while(err == 1) MMAP_LED = 1<<8;
        //load spi
        uint32_t left_to_read = APP_SIZE;
        uint8_t *app_addr = APP_ADDR;
        uint32_t flash_addr = 0;
        while (left_to_read > 0)
        {
            uint32_t chunk_size = SPI_BUFFER_SIZE - 4;
            if (chunk_size > left_to_read)
                chunk_size = left_to_read;

            flash_read_data(app_addr, flash_addr, chunk_size);

            app_addr += chunk_size;
            flash_addr += chunk_size;
            left_to_read -= chunk_size;
        }
        __clock(clk);
        do
        {
            __clock(nclk);
        } while (nclk - clk < CLK_FREQ);
        

        app_start_t app_start = (app_start_t)APP_ADDR;
        MMAP_LED = 0;
        app_start();

    }
    //memory test
    // do{
    //     int *mem = 0;
    //     short *mems = 0;
    //     int flag = 0;
    //     const int NUM = 64 *1024*1024 / sizeof(int);//all 64M
    //     MMAP_LED = 1 << 9;
    //     for(int i = 0; i < NUM; ++i) //write 1
    //         mem[i] = i;
    //     MMAP_LED = 1 << 8;
    //     for(int i = 0; i < NUM; ++i) //read 1
    //         if(mem[i] != i)
    //         {
    //             rescode = 1;
    //             break;
    //         }
    //     if(rescode) goto ERR;

    //     MMAP_LED = 1 << 7;//write 2 2bytes
    //     for(int i = 0; i < NUM*sizeof(int)/sizeof(short); ++i) //write 2
    //         mems[i] = i;
    //     MMAP_LED = 1 << 6;
    //     for(int i = 0; i < NUM*sizeof(int)/sizeof(short); ++i) //read 2
    //         if(mems[i] != (short)i)
    //         {
    //             rescode = 1;
    //             break;
    //         }
    //     ERR: if(rescode) //err, hang
    //     {
    //         MMAP_LED = 1<<1;
    //         while(MMAP_LED || 1);
    //     }
    // }while(0);

    while(1)
    {
        MMAP_LED = 1<<0;
        char cmd;
        cmd = getc();
        check_gen = 0;
        switch(cmd)
        {
            case 's':
                MMAP_LED = 1 << 9;
                //get size
                _putchar('s');
                get_word(&len);
                //get start
                get_word((int*)&start);
                for(int i = 0; i < len; ++i)
                {
                    *(start+i) = getc();
                    check_gen += *(start+i);
                }
                //get checksum
                get_word(&checksum);
                _putchar(checksum != check_gen);
                MMAP_LED = 0;
                break;
            
            case 'j':
                MMAP_LED = 0;
                _putchar('j');
                get_word(&len);
                ((void (*)())(len))();
                break;
            default:
                break;
        }
    }

    while(1);
}

__attribute__((noreturn, naked, __section__(".bootcode"))) void boot()
{
    // asm volatile("la sp, __stack_top"::);
    asm volatile("la sp, 67108864"::);
    main();
    asm("unimp");
}