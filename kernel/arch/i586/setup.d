/**
 * x86 architecture setup code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.setup;

import kernel.core;
import kernel.event;

import std.stdio;
import std.port;

import kernel.arch.i586.constants;
import kernel.arch.i586.common;
import kernel.arch.i586.paging;
import kernel.arch.i586.registers;
import kernel.arch.i586.descriptors;
import kernel.arch.i586.interrupts;
import kernel.arch.i586.pic;
import kernel.arch.i586.screen;

version(arch_i586):

PageTable* arch_init()
{
    disable_interrupts();

    PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);

    setup_gdt();
    setup_tss();
    setup_interrupts();
    
    screen_mem = cast(byte*)(KERNEL_VIRTUAL_BASE + 0xB8000);
    clear_screen();
    
    return pagetable;
}

void arch_setup()
{
    PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);
    
    pagetable.unmap(0);
    
    root.addHandler("dev.pit", EventHandler(0, &pit_handler));
}

void pit_handler(char[] domain)
{
    static size_t time;
    
    time++;
    
    writefln("time: %u", time);
    
    outp(PIC1, PIC_EOI);
}
