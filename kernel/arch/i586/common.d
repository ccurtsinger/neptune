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
