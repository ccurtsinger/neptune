/**
 * i586 (x86) Architecture Support
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.arch;

import kernel.arch.i586.constants;
import kernel.arch.i586.paging;
import kernel.arch.i586.registers;
import kernel.arch.i586.descriptors;
import kernel.arch.i586.interrupts;
import kernel.arch.i586.screen;

import std.stdio;

version(arch_i586):

PageTable* startup()
{
    disable_interrupts();

    PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);

    setup_gdt();
    setup_tss();
    setup_interrupts();
    
    enable_interrupts();
    
    screen_mem = cast(byte*)pagetable.reverseLookup(cast(void*)0xB8000);
    clear_screen();
    
    return pagetable;
}

size_t ptov(size_t p_addr)
{
    PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);
    
    size_t v = pagetable.reverseLookup(p_addr);
    
    assert(v != 0, "Physical page unavailable");
    
    return v;
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

void load_page_table(size_t pagetable)
{
    cr3 = pagetable;
}
