C_FILES := main.c spi.c flash.c printf.c
H_FILES := spi.h flash.h printf.h

ifeq ($(shell uname -s),Darwin)
	TOOLCHAIN := riscv64-unknown-elf
else
	TOOLCHAIN := riscv32-unknown-elf
endif
ARCH := rv32i
ABI := ilp32

C_FLAGS := -march=$(ARCH) -mabi=$(ABI) -mstrict-align -Os -g -ffreestanding -nostdlib -T bootloader.ld -Wl,--no-warn-rwx-segments -I../inc -lgcc

.PHONY: build clean

build: build/bootloader.hex

build/bootloader.hex: $(C_FILES) $(H_FILES)
	$(TOOLCHAIN)-gcc $(C_FILES) -o build/bootloader.o $(C_FLAGS)
	$(TOOLCHAIN)-objcopy -O binary build/bootloader.o build/bootloader.bin
	python3 ../tools/bin_to_hex.py build/bootloader.bin > build/bootloader.hex
	$(TOOLCHAIN)-objdump -d --disassembler-color=terminal build/bootloader.o > build/bootloader.s

clean:
	rm -rf build

$(shell mkdir -p build)
