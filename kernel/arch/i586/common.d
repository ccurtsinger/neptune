/**
 * x86 architecture common operations
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.common;

import kernel.arch.i586.constants;
import kernel.arch.i586.registers;
import kernel.arch.i586.descriptors;
import kernel.arch.i586.paging;

version(arch_i586):

struct Context
{
    uint eax;
    uint ebx;
    uint ecx;
    uint edx;
    uint esi;
    uint edi;
    uint ebp;
    uint eip;
    uint cs;
    uint flags;
    uint esp;
    uint ss;
}

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

PageTable* get_page_table()
{
    return cast(PageTable*)((cr3 & 0xFFFFF000) + KERNEL_VIRTUAL_BASE);
}

void load_page_table(size_t p)
{
    assert(p % 0x1000 == 0, "Page table must be aligned to 0x1000 bytes");
    cr3 = p & 0xFFFFF000;
}
