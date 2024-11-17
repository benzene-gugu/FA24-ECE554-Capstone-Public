#pragma once

#include <stdint.h>

#define FLASH_EXPECTED_ID (0x001f8901)

uint32_t flash_read_id();
void flash_read_data(uint8_t *dst, uint32_t flash_addr, uint32_t size);
