ENTRY(_loader)
SECTIONS
{
    . = 0xffffffff80000000;

    /DISCARD/ :
    { 
        *(.comment)
        *(.note)
        *(.eh_frame)
    }

    .text : AT(ADDR(.text) - 0xffffffff80000000 + 0x1000000)
    {
        code = .;
		*(.text)
		. = ALIGN(4096);
    }

    .data : AT(ADDR(.data) - 0xffffffff80000000 + 0x1000000)
    {
        data = .;
		*(.data)
		. = ALIGN(4096);
    }
    
    .rodata : AT(ADDR(.rodata) - 0xffffffff80000000 + 0x1000000)
    {
        rodata = .;
		*(.rodata)
		start_ctors = .;
		*(.ctor*)
		end_ctors = .;
		start_dtors = .;
		*(.dtor*)
		end_dtors = .;
		. = ALIGN(4096);
    }

    .bss : AT(ADDR(.bss) - 0xffffffff80000000 + 0x1000000)
    {
		*(.bss)
		. = ALIGN(4096);
    }
}
