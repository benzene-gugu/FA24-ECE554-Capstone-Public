#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "printf.h"
#include "tinyalloc.h"
#include "memmap.h"
#include "vga.h"
#include "consts.h"
#include "file.h"
#include "flash.h"
#include "str.h"
#include "spi.h"

#define IMPORT_BIN(sect, file, sym) asm(                                    \
    ".section " #sect "\n"                  /* Change section */            \
    ".balign 4\n"                           /* Word alignment */            \
    ".global " #sym "\n"                    /* Export the object address */ \
    #sym ":\n"                              /* Define the object label */   \
    ".incbin \"" file "\"\n"                /* Import the file */           \
    ".global _sizeof_" #sym "\n"            /* Export the object size */    \
    ".set _sizeof_" #sym ", . - " #sym "\n" /* Define the object size */    \
    ".balign 4\n"                           /* Word alignment */            \
    ".section \".text\"\n")                 /* Restore section */
// http://elm-chan.org/junk/32bit/binclude.html

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpointer-to-int-cast"
#pragma GCC diagnostic ignored "-Wint-to-pointer-cast"

#define DOOM_IMPLEMENTATION
#include "PureDOOM.h"

#pragma GCC diagnostic pop

#define HEAP_SIZE (16 * 1024 * 1024)
#define HEAP_START ((uint8_t *)(16 * 1024 * 1024))
#define HEAP_END (HEAP_START + HEAP_SIZE)

#define SW_UP (1 << 7)
#define SW_LEFT (1 << 9)
#define SW_DOWN (1 << 8)
#define SW_RIGHT (1 << 6)
#define SW_STRAFE (1 << 5)
#define BTN_USE (1 << 11)
#define BTN_FIRE (1 << 12)
#define SW_SPEED (1 << 4)

#define KEY_UP DOOM_KEY_UP_ARROW
#define KEY_LEFT DOOM_KEY_LEFT_ARROW
#define KEY_DOWN DOOM_KEY_DOWN_ARROW
#define KEY_RIGHT DOOM_KEY_RIGHT_ARROW
#define KEY_STRAFE DOOM_KEY_C
#define KEY_USE DOOM_KEY_ENTER
#define KEY_FIRE DOOM_KEY_F
#define KEY_SPEED DOOM_KEY_S

IMPORT_BIN(".doomwad", "doom1.wad", doomwad_data);
extern const char doomwad_data[]; // best to read from SPI flash in fread
extern const char _sizeof_doomwad_data[];

file_t files[] = {
    {.filename = "./doom1.wad",
     .data = doomwad_data,
     .size = (uint32_t)_sizeof_doomwad_data,
     .offset = 0,
     .is_open = false}};
const uint32_t FILE_COUNT = sizeof(files) / sizeof(file_t);

void *memcpy(void *dest, const void *src, size_t n)
{
    return doom_memcpy(dest, src, n);
}

char getc()
{
    while (GET_UART_RX_QLEN(MMAP_UART_CTRL) == 0)
        ;
    char input = MMAP_UART_QUEU;
    _putchar(input); // echo back
    return input;
}

void doomed_print(const char *str)
{
    printf("%s", str);
}

void *doomed_malloc(int size)
{
    void *result = ta_alloc(size);

    // if (!ta_check())
    // {
    //     printf("Heap corrupted after allocating %x\r\n", size);
    // }

    return result;
}

void doomed_free(void *ptr)
{
    if (!ta_free(ptr))
    {
        printf("Free failed on %x!\r\n", ptr);
    }

    // if (!ta_check())
    // {
    //     printf("Heap corrupted after freeing %x\r\n", ptr);
    // }
}

void *doomed_open(const char *filename, const char *mode)
{
    printf("open(\"%s\", \"%s\")\r\n", filename, mode);

    for (uint32_t i = 0; i < FILE_COUNT; i++)
    {
        file_t *file = &files[i];

        if (strcmp(filename, file->filename) == 0)
        {
            if (file->is_open)
                printf("Opening already open file %s!\r\n", file->filename);

            file->is_open = true;
            return file;
        }
    }

    return NULL;
}

void doomed_close(void *handle)
{
    file_t *file = (file_t *)handle;

    if (!file->is_open)
    {
        printf("Trying to close %s without it being open!\r\n", file->filename);
    }

    file->is_open = false;
}

int doomed_read(void *handle, void *buf, int count)
{
    file_t *file = (file_t *)handle;

    if (handle == NULL || buf == NULL)
    {
        printf("Null arg in read()!\r\n");
        return -1;
    }

    if (file->offset + count > file->size)
        count = file->size - file->offset;

    uint32_t left_to_read = count;
    uint8_t *dst_addr = buf;
    uint32_t flash_addr = (uint32_t)file->data + file->offset;
    while (left_to_read > 0)
    {
        uint32_t chunk_size = SPI_BUFFER_SIZE - 4;
        if (chunk_size > left_to_read)
            chunk_size = left_to_read;

        flash_read_data(dst_addr, flash_addr, chunk_size);

        dst_addr += chunk_size;
        flash_addr += chunk_size;
        left_to_read -= chunk_size;
    }

    return count;
}

int doomed_write(void *handle, const void *buf, int count)
{
    file_t *file = (file_t *)handle;

    if (handle == NULL || buf == NULL)
    {
        printf("Null arg in write()!\r\n");
        return -1;
    }

    printf("Ignored write to %s of %d bytes.\r\n", file->filename, count);

    return count;
}

int doomed_seek(void *handle, int offset, doom_seek_t origin)
{
    file_t *file = (file_t *)handle;

    if (handle == NULL)
    {
        printf("Null arg in seek()!\r\n");
        return -1;
    }

    int32_t start;

    switch (origin)
    {
    case DOOM_SEEK_CUR:
        start = file->offset;
        break;
    case DOOM_SEEK_END:
        start = file->size;
        break;
    case DOOM_SEEK_SET:
        start = 0;
        break;
    default:
        printf("Invalid origin arg in seek() of %s!\r\n", file->filename);
    }

    int32_t new_offset = start + offset;

    if (new_offset < 0)
        new_offset = 0;

    if (new_offset > file->size)
        new_offset = file->size;

    file->offset = new_offset;

    return 0;
}

int doomed_tell(void *handle)
{
    file_t *file = (file_t *)handle;

    if (handle == NULL)
    {
        printf("Null arg in tell()!\r\n");
        return -1;
    }

    return file->offset;
}

int doomed_eof(void *handle)
{
    file_t *file = (file_t *)handle;

    if (handle == NULL)
    {
        printf("Null arg in eof()!\r\n");
        return -1;
    }

    return file->offset == file->size;
}

void doomed_gettime(int *sec, int *usec)
{
    uint32_t cyclesl, cyclesh;
    __asm__ volatile("rdcycle %0" : "=r"(cyclesl));
    __asm__ volatile("rdcycleh %0" : "=r"(cyclesh));
    uint64_t cycles = (uint64_t)cyclesh << 32 | (uint64_t)cyclesl;
    *sec = cycles / CLK_FREQ;
    *usec = cycles / (CLK_FREQ / (1000 * 1000));
    // printf("gettime: %d s %d us\r\n", *sec, *usec);
}

void doomed_exit(int code)
{
    printf("Doom exitted with code %d\r\n", code);
}

char *doomed_getenv(const char *var)
{
    printf("getenv(\"%s\")\r\n", var);
    return NULL;
}

void handle_input_key(uint32_t cur, uint32_t prev, uint32_t bit, doom_key_t key)
{
    if ((cur & bit) > (prev & bit))
        doom_key_down(key);
    else if ((cur & bit) < (prev & bit))
        doom_key_up(key);
}

void handle_input(uint32_t cur, uint32_t prev)
{
    handle_input_key(cur, prev, SW_UP, KEY_UP);
    handle_input_key(cur, prev, SW_LEFT, KEY_LEFT);
    handle_input_key(cur, prev, SW_DOWN, KEY_DOWN);
    handle_input_key(cur, prev, SW_RIGHT, KEY_RIGHT);
    handle_input_key(cur, prev, SW_STRAFE, KEY_STRAFE);
    handle_input_key(cur, prev, BTN_USE, KEY_USE);
    handle_input_key(cur, prev, BTN_FIRE, KEY_FIRE);
    handle_input_key(cur, prev, SW_SPEED, KEY_SPEED);
}

__attribute__((__section__(".start"))) void start()
{
    printf("Hello from DOOM!\r\n");

    ta_init(HEAP_START, HEAP_END, 16 * 1024, 16, 4);

    if (!ta_check())
    {
        printf("Heap failed to initialize\r\n");
    }

    doom_set_print(doomed_print);
    doom_set_malloc(doomed_malloc, doomed_free);
    doom_set_file_io(doomed_open, doomed_close, doomed_read, doomed_write, doomed_seek, doomed_tell, doomed_eof);
    doom_set_gettime(doomed_gettime);
    doom_set_exit(doomed_exit);
    doom_set_getenv(doomed_getenv);

    doom_set_default_int("key_up", KEY_UP);
    doom_set_default_int("key_down", KEY_DOWN);
    doom_set_default_int("key_left", KEY_LEFT);
    doom_set_default_int("key_right", KEY_RIGHT);

    doom_set_default_int("key_fire", KEY_FIRE);
    doom_set_default_int("key_use", KEY_USE);
    doom_set_default_int("key_strafe", KEY_STRAFE);
    doom_set_default_int("key_speed", KEY_SPEED);

    char *argv[] = {"doom"};
    int32_t argc = sizeof(argv) / sizeof(argv[0]);
    doom_init(argc, argv, 0);

    uint32_t cur_input, prev_input;
    while (true)
    {
        // int sec, usec;
        // doomed_gettime(&sec, &usec);
        // printf("DOOMED: ticking update %d s or %d us\r\n", sec, usec);

        cur_input = MMAP_HIN;
        handle_input(cur_input, prev_input);
        prev_input = cur_input;

        doom_update();

        uint32_t ihit, imiss, dhit, dmiss;
        __read_csr(CSR_IHIT, ihit);
        __read_csr(CSR_IMISS, imiss);
        __read_csr(CSR_DHIT, dhit);
        __read_csr(CSR_DMISS, dmiss);

        // printf("Cache: %u %u %u %u\r\n", ihit, imiss, dhit, dmiss);

        uint8_t *screen = screens[0];
        for (uint32_t y = 0; y < SCREENHEIGHT; y++)
        {
            for (uint32_t x = 0; x < SCREENWIDTH; x++)
            {
                uint32_t screen_index = y * SCREENWIDTH + x;
                uint32_t kpal = screen[screen_index] * 3;
                uint8_t r, g, b;
                r = screen_palette[kpal + 0];
                g = screen_palette[kpal + 1];
                b = screen_palette[kpal + 2];

                SET_RGB_AT(r, g, b, MMAP_FRAMEBUFF + 20 * SCREENWIDTH + screen_index);
            }
        }
    }
}
