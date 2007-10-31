ENTRY(_loader)
SECTIONS
{
    . = 0xffffffff80000000;

    .text : AT(ADDR(.text) - 0xffffffff80000000 + 0x1000000)
    {
        code = .;
		*(.text)
		*(.rodata)
		. = ALIGN(4096);
    }

    .data : AT(ADDR(.data) - 0xffffffff80000000 + 0x1000000)
    {
        data = .;
		*(.data)
		. = ALIGN(4096);
		
		start_ctors = .;
		*(.ctor*)
		end_ctors = .;
    }

    .bss : AT(ADDR(.bss) - 0xffffffff80000000 + 0x1000000)
    {
		stack = .;
		*(.bss)
		. = ALIGN(4096);
    }

    .ehframe : AT(ADDR(.ehframe) - 0xffffffff80000000 + 0x1000000)
    {
        ehframe = .;
        *(.ehframe)
        . = ALIGN(4096);
    }
}
