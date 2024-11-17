C_FILES := firmware.c
H_DIR := inc
OBJ_DIR := build

ifeq ($(shell uname -s),Darwin)
	TOOLCHAIN := riscv64-unknown-elf
else
	TOOLCHAIN := riscv32-unknown-elf
endif

ARCH := rv32i_zicsr
ABI := ilp32

C_FLAGS := -I$(H_DIR) -march=$(ARCH) -mabi=$(ABI) -mstrict-align -Os -g -ffreestanding -nostdlib -T link.ld -Wl,--no-warn-rwx-segments -lgcc

.PHONY: build clean

build_all: build/firmware.hex

build/firmware.hex: $(C_FILES)
	$(TOOLCHAIN)-gcc  $(C_FILES) -o build/firmware.o $(C_FLAGS)
	$(TOOLCHAIN)-objcopy -O binary build/firmware.o build/firmware.bin
	python3 ../../../sw/tools/bin_to_hex.py build/firmware.bin > build/firmware.hex
	$(TOOLCHAIN)-objdump -d --disassembler-color=terminal build/firmware.o
	python3 ../convert-to-4banks.py build .hex
	$(TOOLCHAIN)-objdump -d --disassembler-color=terminal build/firmware.o > build/firmware.txt
clean:
	rm -rf build
	rm -rf *.vh

$(shell mkdir -p build)
$(shell mkdir -p ../hw/firmwarehex)