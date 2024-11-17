#define PRINTF_DISABLE_SUPPORT_FLOAT
#define PRINTF_DISABLE_SUPPORT_EXPONENTIAL
#define PRINTF_DISABLE_SUPPORT_LONG_LONG 
#include "printf.h"
#include "../inc/memmap.h"
#include "../inc/vga.h"
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

//int isprint(int c)
// {
// 	return ((c >= ' ' && c <= '~') ? 1 : 0);
// }

void _putchar(char character)
{
  while(GET_UART_TX_QREM(MMAP_UART_CTRL) == 0);
  MMAP_UART_QUEU = character;
}

char getc()
{
    while(GET_UART_RX_QLEN(MMAP_UART_CTRL) == 0);
    char input = MMAP_UART_QUEU;
    _putchar(input); //echo back
    return input;
}

// char getc_nonblocking()
// {
//     if(GET_UART_RX_QLEN(MMAP_UART_CTRL) > 0)
//     {
//         char input = MMAP_UART_QUEU;
//         _putchar(input); //echo back
//         return input;
//     }
//     else
//         return 0;
// }

// int gets(char *buf, int size_buf)
// {
//     char *ptr = buf, *endptr = buf+size_buf-1;
//     char input;
//     while(ptr < endptr)
//     {
//         input = getc_nonblocking();
//         if(isprint(input) == 0 && input != '\r') continue; //no valid input continue
//         *(ptr++) = input;
//         if(input == '\r')
//             break;
//     }
//     *ptr = '\0';
//     return ptr - buf; //return len
// }

// void generate_test_vga_pattern()
// {
//     unsigned int v_off;
//     volatile unsigned int *addr;
//     for(int y = 0; y < 480; ++y)
//         for(int x = 0; x < 640; ++x)
//         {
//             v_off = (y*640 + x)<<2;
//             addr = MMAP_FRAMEBUFF + v_off;
//             if(x > 320 && y > 240)
//                 SET_RGB_AT(0, 0, 0, addr);
//             else if(x < 320 && y > 240)
//                 SET_RGB_AT(3, 1, 2, addr);
//             else if (x > 320 && y < 240)
//                 SET_RGB_AT(1, 3, 2, addr);
//             else 
//                 SET_RGB_AT(2, 1, 3, addr);
//             //SET_RGB_AT(2, 1, 3, addr);
//         }
// }


// void get_word(int *dest)
// {
//     for(int i = 0; i < 4; ++i)
//     {
//         *dest <<= 8;
//         *dest |= getc();
//     }
// }

// char getc_nonblocking()
// {
//     if(GET_UART_RX_QLEN(MMAP_UART_CTRL) > 0)
//     {
//         char input = MMAP_UART_QUEU;
//         _putchar(input); //echo back
//         return input;
//     }
//     else
//         return 0;
// }

// int gets(char *buf, int size_buf)
// {
//     char *ptr = buf, *endptr = buf+size_buf-1;
//     char input;
//     while(ptr < endptr)
//     {
//         input = getc_nonblocking();
//         if(isprint(input) == 0 && input != '\r') continue; //no valid input continue
//         *(ptr++) = input;
//         if(input == '\r')
//             break;
//     }
//     *ptr = '\0';
//     return ptr - buf; //return len
// }

// void generate_test_vga_pattern()
// {
//     unsigned int v_off;
//     volatile unsigned int *addr;
//     for(int y = 0; y < 480; ++y)
//         for(int x = 0; x < 640; ++x)
//         {
//             v_off = (y*640 + x)<<2;
//             addr = MMAP_FRAMEBUFF + v_off;
//             if(x > 320 && y > 240)
//                 SET_RGB_AT(0, 0, 0, addr);
//             else if(x < 320 && y > 240)
//                 SET_RGB_AT(3, 1, 2, addr);
//             else if (x > 320 && y < 240)
//                 SET_RGB_AT(1, 3, 2, addr);
//             else 
//                 SET_RGB_AT(2, 1, 3, addr);
//             //SET_RGB_AT(2, 1, 3, addr);
//         }
// }


// void get_word(int *dest)
// {
//     for(int i = 0; i < 4; ++i)
//     {
//         *dest <<= 8;
//         *dest |= getc();
//     }
// }

void swap(int arr[] , int pos1, int pos2){
	int temp;
	temp = arr[pos1];
	arr[pos1] = arr[pos2];
	arr[pos2] = temp;
}

int partition(int arr[], int low, int high, int pivot){
	int i = low;
	int j = low;
	while( i <= high){
		if(arr[i] > pivot){
			i++;
		}
		else{
			swap(arr,i,j);
			i++;
			j++;
		}
	}
	return j-1;
}

void quickSort(int arr[], int low, int high){
	if(low < high){
	int pivot = arr[high];
	int pos = partition(arr, low, high, pivot);
	
	quickSort(arr, low, pos-1);
	quickSort(arr, pos+1, high);
	}
}

int xorshift32(int x)
{
    x |= x == 0;   // if x == 0, set x = 1 instead
    x ^= (x & 0x0007ffff) << 13;
    x ^= x >> 17;
    x ^= (x & 0x07ffffff) << 5;
    return x & 0xffffffff;
}

int colors[] = {45, 63, 10, 32, 0, 20};
int a[1024];
__attribute__(( __section__(".mainfun")))void main()
{
    unsigned int clk = 0, cur;
    // volatile int *wbptr = a + 16384/4;
    // for(int i = 0; i < sizeof(a)/sizeof(int); ++i)
    //     // x = a[i] = xorshift32(x);
    //     a[i] = i;
    // for(int i = 0; i < sizeof(a)/sizeof(int); i += 1)
    //     x = wbptr[i];
    // getc();
    unsigned int v_off;
    volatile unsigned int *addr;
    int col = 0;
    int ihit, imiss, dhit, dmiss;
    unsigned int prevclk = 0, curclk;
    while(1)
    {
        __read_csr(CSR_IHIT, ihit);
        __read_csr(CSR_IMISS, imiss);
        __read_csr(CSR_DHIT, dhit);
        __read_csr(CSR_DMISS, dmiss);
        do
        {
            __clock(curclk);
        } while (curclk - prevclk < 50000000);
        prevclk = curclk;
        printf("Icache hit:  %u \r\nIcache miss: %u \r\nDcache hit:  %u \r\nDcache miss: %u \r\n", ihit, imiss, dhit, dmiss);
        printf("User input: %x\r\n", MMAP_HIN>>12);
        for(int i = 0; i < sizeof(a)/sizeof(int); ++i)
            a[i] = i;
    }
    
    //while(MMAP_LED);
    // char in;
    // unsigned int v_off;
    // volatile unsigned int *addr;
    // char col = 0;
    // while(1)
    // {
    //     for(int y = 0; y < 480; ++y)
    //     for(int x = 0; x < 640; ++x)
    //     {
    //         v_off = (y*640 + x)<<2;
    //         addr = MMAP_FRAMEBUFF + v_off;
    //         SET_RGB_AT(col, 0, 0, addr);
    //     }
    //     col = col == 0 ? 3 : 0;
    //     getc();
    // }

    unsigned long cycles, inst_ret, last_cycles, last_inst_ret;
    asm volatile ("rdcycle %0" : "=r" (cycles));
    asm volatile ("rdinstret %0" : "=r" (inst_ret));
    getc();
    last_cycles = cycles;
    printf("cycles: %u, inst_ret: %u\r\n", cycles, inst_ret);
    int x = 128;
    for(int i = 0; i < sizeof(a)/sizeof(int); ++i)
        x = a[i] = xorshift32(x);
    
    asm volatile ("rdcycle %0" : "=r" (last_cycles));
    asm volatile ("rdinstret %0" : "=r" (last_inst_ret));
    quickSort(a, 0, sizeof(a)/sizeof(int)-1);
    asm volatile ("rdcycle %0" : "=r" (cycles));
    asm volatile ("rdinstret %0" : "=r" (inst_ret));

    for(int i = 0; i < sizeof(a)/sizeof(int); ++i)
    {
        printf("%d\r\n", a[i]);
    }
    printf("Done\r\n");

    printf("sort: dcycles: %u, dinst_ret: %u\r\n", cycles-last_cycles, inst_ret-last_inst_ret);

    while(1)
    {
        getc();
        asm volatile ("rdcycle %0" : "=r" (cycles));
        asm volatile ("rdinstret %0" : "=r" (inst_ret));
        printf("cycles: %u, inst_ret: %u\r\n", cycles-last_cycles, inst_ret);
        last_cycles = cycles;
    };
}
