MEMORY
{
   BRAM (RWX) : ORIGIN = 32M, LENGTH = 64K
}

SECTIONS
{
    main :
    {
        . = ALIGN(4);
        *(.mainfun)
    }
    everything :
    {
        . = ALIGN(4);
        *(.text)
        . = ALIGN(4);
        *(.text.*)
        . = ALIGN(4);
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
