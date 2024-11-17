#pragma once

#include <stdint.h>
#include <stdbool.h>

typedef struct
{
    const char *filename;
    const uint8_t *data;
    uint32_t size;
    uint32_t offset;
    bool is_open;
} file_t;
