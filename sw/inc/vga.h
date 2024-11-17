#pragma once

#define VGA_WIDTH (320)
#define VGA_HEIGHT (240)

#define SET_RGB_AT(R, G, B, PTR) (*(PTR) = (((R) & 0xff) << 16) | (((G) & 0xff) << 8) | ((B) & 0xff))
