MEMORY
{
  ram      (rwx) : ORIGIN = 0x00000000, LENGTH = 64M /*16K*/
  rom       (rx) : ORIGIN = 0x08000000, LENGTH =  4K
}

/* Section Definitions */
SECTIONS
{
	PROVIDE(__stack_top = ORIGIN(ram) + LENGTH(ram));

    .main :
	{
        . = ALIGN(4);
        *(.mainfun)
	} >ram
    .everything :
    {
        *(.text)
        *(.text.*)
        *(.data)
        . = ALIGN(4);
        *(.data.*)
        . = ALIGN(4);
        *(.bss)
        . = ALIGN(4);
        *(.bss.*)
        . = ALIGN(4);
        *(.rodata)
        . = ALIGN(4);
        *(.rodata.*)
        . = ALIGN(4);
    } >ram

    _end = . ;


    .rom_code :
    {
        *(.bootcode)
        *(.bootrom)
    } > rom
}
