/**
 * x86 architecture common operations
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.common;

import kernel.arch.i586.constants;
import kernel.arch.i586.registers;
import kernel.arch.i586.descriptors;

version(arch_i586):

void disable_interrupts()
{
    asm{"cli";}
}

void enable_interrupts()
{
    asm{"sti";}
}

void set_kernel_entry_stack(size_t p)
{
    tss.ss0 = GDTSelector.KERNEL_DATA;
    tss.esp0 = p;
}

void load_page_table(size_t p)
{
    assert(p % 0x1000 == 0, "Page table must be aligned to 0x1000 bytes");
    cr3 = p & 0xFFFFF000;
}
