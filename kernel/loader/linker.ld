ENTRY(_loader)
SECTIONS
{
    . = 0x100000;

    mboot :
    {
	*(mboot)
    }

    .text :
    {
	code = .;
	*(.text)
    }

    .rodata :
    {
	*(.rodata)
    }

    data = .;

    .data :
    {
	*(.data)
    }

    bss = .;

    .bss :
    {
	*(.bss)
    }

    end = .;

    /DISCARD/ : { *(.comment .note .eh_frame) }
}
