453-06
# Doomed Address Map

Unspecified address ranges are reserved and should not be accessed.

Start Address | End Address | Description
------------- | ----------- | -----------
0x0000_0000   | 0x0400_0000 | [Main Memory](#main-memory)
0x0400_0000   | 0x0800_0000 | [Cache Ctrl](#main-memory)
0x0800_0000   | 0x0800_1000 | [ROM 4KB](#main-memory)
0x1000_0000   | 0x1000_000C | [UART](#uart)
0x1000_0010   | 0x1000_0014 | [10LEDR](#humanio)
0x1000_0020   | 0x1000_0024 | [10SW&3key](#humanio)
0x1100_0000   | 0x1100_1008 | [SPI](#spi)
0x1200_0000   | 0x1212 C000 | [VGA](#vga)



## Main Memory

Start Address | End Address | Description
------------- | ----------- | -----------
0x0000_0000   | 0x0100_0000 | Stack (sp starts at 0x0100_0000)
0x0100_0000   | 0x0400_0000 | Everything else

Any write/read to Cache Ctrl range will evict iCache. It does not have impact on other memory, regardless of r/w.

## UART

Start Address | End Address | R/W | Description
------------- | ----------- | :-: | -----------
0x1000_0000   | 0x1000_0004 | R/W | [Control](#uart-control)
0x1000_0004   | 0x1000_0008 | R/W   |[RX/TX Queue](#uart-queue)

### UART: Control
Access must be aligned to 4 bytes.

```
     3         2         1         0
     1         3         5         7
32'b xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
     |         |         |__________________ Baud rate 
     |         |____________________________ TX empty entries
     |                   
     |______________________________________ RX filled entries
```

#### UART: Control - Baud rate

Defaults to 16'd868 which gives approximately an 1152000 baud rate at 100 MHz.

Writes to this set the period of the UART block in cycles.

### UART: Queue
TX and RX queue share the same address.

The TX queue has a size of 8 entries.

Writes to this address will be truncated to 8 bits and will push to the TX queue.
If there is no room left in the queue, nothing will be added to the queue.

The RX queue has a size of 8 entries.

Reading from this will pop an entry from the RX queue.
If there is nothing left in the queue, unspecified values will be returned.

### Human IO: 
LEDR0 to LEDR9 are bit[0] to bit[9] of the 32-bit word.
{key[3:1], sw[9:0]} are bit[12:0] of the word.

## SPI

The SPI peripheral is clocked at 10 MHz.

Start Address | End Address | R/W | Description
------------- | ----------- | :-: | -----------
0x1100_0000   | 0x1100_0004 | R/W | [Control](#spi-control)
0x1100_0008   | 0x1100_1008 | R/W | [Buffer](#spi-buffer)

### SPI: Control

```
     3         2         1         0
     1         3         5         7
32'b xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
                           |              || Quad mode
                           |              |_ Slave select
                           |________________ TX size
```

#### SPI: Control - Quad mode

Defaults to 0.

A value of 0 indicates single SPI mode.

A value of 1 indicates quad SPI (QSPI) mode.

#### SPI: Control - Slave select

Defaults to 1. Active low.

A value of 0 indicates an assertion of slave select.

A value of 1 indicates a deassertion of slave select.

#### SPI: Control - TX size

Write a value n > 0 to start a SPI transfer. When a transfer starts n bytes will be written and bytes received will overwrite the contents of the SPI buffer.

### SPI: Buffer

This buffer is used to store transferred and received bytes.


## VGA

Start Address | End Address | R/W | Description
------------- | ----------- | :-: | -----------
0x1200_0000   | 0x1212 C000 | R/W | [Buffer](#vga-buffer)

### VGA: Buffer

This buffer is used to store what is currently being displayed over VGA.
This is also referred to as the framebuffer.
Access must be aligned to 4 bytes.
Resolution WxH is 640*480. Each pixel is 4 bytes long, but only the lower 6 bits are valid.
Address at row y, x column = BASE + (y*640 + x)<<2.
Lower 6 bits: 5      0
              XX XX XX
              R  G  B

