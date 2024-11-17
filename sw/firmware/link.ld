MEMORY
{
  ram      (rwx) : ORIGIN = 0x00000000, LENGTH = 64M /*16K*/
  rom       (rx) : ORIGIN = 0x08000000, LENGTH =  4K
}

/* Section Definitions */
SECTIONS
{
	PROVIDE(__stack_top = ORIGIN(ram) + LENGTH(ram));
    .text :
    {
        *(.bootcode)
        *(.bootrom)
        KEEP(*(.vectors .vectors.*))
        *(.text*)
        *(.rodata*)
    } > rom

    /* .bss section which is used for uninitialized data */
    .bss (NOLOAD) :
    {
        *(.bss*)
        *(COMMON)
    } > ram
    /*.data :
    {
        *(.data*);
    } > ram AT >rom
    Only use stack vars in bootloader No data section*/

    _end = . ;
}
