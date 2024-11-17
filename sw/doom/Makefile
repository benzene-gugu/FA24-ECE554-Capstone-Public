C_FILES := main.c printf.c tinyalloc.c spi.c flash.c str.c
H_FILES := PureDOOM.h printf.h tinyalloc.h file.h spi.h flash.h str.h

ifeq ($(shell uname -s),Darwin)
	TOOLCHAIN := riscv64-unknown-elf
else
	TOOLCHAIN := riscv32-unknown-elf
endif
ARCH := rv32im_zicsr
ABI := ilp32

C_FLAGS := -march=$(ARCH) -mabi=$(ABI) -mstrict-align -Os -g -ffreestanding -nostdlib -T doom.ld -Wl,--no-warn-rwx-segments -I../inc -lgcc

.PHONY: build clean flash

build: build/doom.bin

program: build/padded_doom.bin
	flashrom -p serprog:dev=/dev/tty.usbmodem1101:115200,spispeed=12M -w build/padded_doom.bin -c AT25SF128A

doom1.wad:
	wget https://raw.githubusercontent.com/Daivuk/PureDOOM/master/doom1.wad

build/doom.bin: $(C_FILES) $(H_FILES) doom1.wad
	$(TOOLCHAIN)-gcc $(C_FILES) -o build/doom.o $(C_FLAGS)
	$(TOOLCHAIN)-objcopy -O binary build/doom.o build/doom.bin
	$(TOOLCHAIN)-objdump -d --disassembler-color=terminal build/doom.o > build/doom.s

build/padded_doom.bin: build/doom.bin
	python3 ../tools/pad_bin.py build/doom.bin 16777216 build/padded_doom.bin

clean:
	rm -rf build

$(shell mkdir -p build)
