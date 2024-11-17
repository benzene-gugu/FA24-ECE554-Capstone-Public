MEMORY
{
   RAM (RWX) : ORIGIN = 0x00000000, LENGTH = 64M
}

SECTIONS
{
    start :
    {
        . = ALIGN(4);
        *(.start)
    } >RAM
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


        . = 8M;

        _end_of_app = .;
        *(.doomwad)
    } >RAM
}
