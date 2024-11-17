MEMORY
{
   BRAM (RWX) : ORIGIN = 0x0000, LENGTH = 64K
}

SECTIONS
{
	PROVIDE(__stack_top = ORIGIN(BRAM) + LENGTH(BRAM));
    main :
	{
        . = ALIGN(4);
        *(.mainfun)
	}
    everything :
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
    } >BRAM
}
