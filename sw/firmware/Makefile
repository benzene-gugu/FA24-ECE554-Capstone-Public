C_FILES := firmware.c spi.c flash.c
H_FILES := 

TOOLCHAIN := riscv32-unknown-elf
ARCH := rv32i
ABI := ilp32

C_FLAGS := -I../inc -march=$(ARCH) -mabi=$(ABI) -mstrict-align -Os -g -ffreestanding -nostdlib -T link.ld -Wl,--no-warn-rwx-segments -lgcc

.PHONY: build clean

build: build/firmware.hex

build/firmware.hex: $(C_FILES) $(H_FILES)
	$(TOOLCHAIN)-gcc  $(C_FILES) -o build/firmware.o $(C_FLAGS)
	$(TOOLCHAIN)-objcopy -O binary build/firmware.o build/firmware.bin
	python3 ../tools/bin_to_hex.py build/firmware.bin > build/firmware.hex
	$(TOOLCHAIN)-objdump -d --disassembler-color=terminal build/firmware.o
	python3 ../convert-to-4banks.py build .hex
	mv *.vh ../../hw/firmwarehex/
	$(TOOLCHAIN)-objdump -d --disassembler-color=terminal build/firmware.o > build/firmware.txt
clean:
	rm -rf build
	rm -rf *.vh

$(shell mkdir -p build)
