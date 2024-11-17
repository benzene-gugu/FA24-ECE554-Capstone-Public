#define PRINTF_DISABLE_SUPPORT_FLOAT
#define PRINTF_DISABLE_SUPPORT_EXPONENTIAL
#define PRINTF_DISABLE_SUPPORT_LONG_LONG

#include "printf.h"
#include "spi.h"

#include <stdbool.h>

#define MMAP_LED *((volatile unsigned int *)0x10000010)
#define MMAP_UART_CTRL *((volatile unsigned int *)0x10000000)
#define MMAP_UART_QUEU *((volatile unsigned int *)0x10000004)
#define MMAP_FRAMEBUFF 0x12000000U

#define GET_UART_RX_QLEN(X) (X >> 24)
#define GET_UART_TX_QREM(X) ((X >> 16) & (0xFF))
#define SET_RGB_AT(R, G, B, PTR) (*(PTR) = (((R) & 3) << 4) | (((G) & 3) << 2) | ((B) & 3))

void memcpy(void *dest, void *src, int n)
{
    // n /= 4;
    char *csrc = (char *)src;
    char *cdest = (char *)dest;

    for (int i = 0; i < n; ++i)
        cdest[i] = csrc[i];
}

int isprint(int c)
{
    return ((c >= ' ' && c <= '~') ? 1 : 0);
}

void _putchar(char character)
{
    while (GET_UART_TX_QREM(MMAP_UART_CTRL) == 0)
        ;
    MMAP_UART_QUEU = character;
}

char getc()
{
    while (GET_UART_RX_QLEN(MMAP_UART_CTRL) == 0)
        ;
    char input = MMAP_UART_QUEU;
    _putchar(input); // echo back
    return input;
}

char getc_nonblocking()
{
    if (GET_UART_RX_QLEN(MMAP_UART_CTRL) > 0)
    {
        char input = MMAP_UART_QUEU;
        _putchar(input); // echo back
        return input;
    }
    else
        return 0;
}

int gets(char *buf, int size_buf)
{
    char *ptr = buf, *endptr = buf + size_buf - 1;
    char input;
    while (ptr < endptr)
    {
        input = getc_nonblocking();
        if (isprint(input) == 0 && input != '\r')
            continue; // no valid input continue
        *(ptr++) = input;
        if (input == '\r')
            break;
    }
    *ptr = '\0';
    return ptr - buf; // return len
}

void generate_test_vga_pattern()
{
    unsigned int v_off;
    volatile unsigned int *addr;
    for (int y = 0; y < 480; ++y)
        for (int x = 0; x < 640; ++x)
        {
            v_off = (y * 640 + x) << 2;
            addr = MMAP_FRAMEBUFF + v_off;
            if (x > 320 && y > 240)
                SET_RGB_AT(0, 0, 0, addr);
            else if (x < 320 && y > 240)
                SET_RGB_AT(3, 1, 2, addr);
            else if (x > 320 && y < 240)
                SET_RGB_AT(1, 3, 2, addr);
            else
                SET_RGB_AT(2, 1, 3, addr);
            // SET_RGB_AT(2, 1, 3, addr);
        }
}

// void print_greets()
// {
//     printf("hello world riscv %d\r\n", 32);
// }

void get_word(int *dest)
{
    for (int i = 0; i < 4; ++i)
    {
        *dest <<= 8;
        *dest |= getc();
    }
}

__attribute__((__section__(".mainfun"))) void main()
{
    uint8_t tx[SPI_BUFFER_SIZE];
    uint8_t rx[SPI_BUFFER_SIZE];

    getc();
    getc();
    getc();

    printf("Hello from SPI tb!\r\n");

    spi_control_reg_t control;
    control.word = SPI_CONTROL_REG;
    control.clk_per_half_cycle = 4;
    SPI_CONTROL_REG = control.word;

    printf("control: %x\r\n", SPI_CONTROL_REG);

    while (true)
    {
        tx[0] = 0x03;
        tx[1] = 0x00;
        tx[2] = 0x00;
        tx[3] = 0x04;
        tx[4] = 0x00;
        tx[5] = 0x00;
        printf("Send: %x %x %x %x %x %x\r\n", tx[0], tx[1], tx[2], tx[3], tx[4], tx[5]);
        spi_set_ss(true);
        spi_transfer(tx, rx, 6);
        spi_set_ss(false);
        printf(" Got: %x %x %x %x %x %x\r\n", rx[0], rx[1], rx[2], rx[3], rx[4], rx[5]);
        getc();
    }

    return;
}
