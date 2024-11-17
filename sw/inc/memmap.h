#pragma once

#define MMAP_LED *((volatile unsigned int *)0x10000010)
#define MMAP_HIN *((volatile unsigned int *)0x10000020)
#define MMAP_UART_CTRL *((volatile unsigned int *)0x10000000)
#define MMAP_UART_QUEU *((volatile unsigned int *)0x10000004)
#define MMAP_FRAMEBUFF ((volatile unsigned int *)0x12000000)

#define CSR_UPPER (0x080)
#define CSR_CLK (0xc00)
#define CSR_IHIT (0xc03)
#define CSR_IMISS (0xc04)
#define CSR_DHIT (0xc05)
#define CSR_DMISS (0xc06)

#define GET_UART_RX_QLEN(X) (X >> 24)
#define GET_UART_TX_QREM(X) ((X >> 16) & (0xFF))

#define __clock(X) asm volatile ("rdcycle %0" : "=r"(X))
#define __read_csr(CSR, X) __asm__ __volatile__ ("csrr %0, %1"             \
              : "=r" (X)                        \
              : "n" (CSR)                       \
              : /* clobbers: none */ );
