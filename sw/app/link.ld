MEMORY
{
   BRAM (RWX) : ORIGIN = 32M, LENGTH = 32M
}

SECTIONS
{
    .main :
	{
        . = ALIGN(4);
        *(.mainfun)
	} >BRAM
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
    } >BRAM
}
