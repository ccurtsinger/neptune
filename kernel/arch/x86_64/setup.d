/**
 * x86 architecture setup code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.x86_64.setup;

import kernel.core;
import kernel.event;

import std.stdio;
import std.port;

import kernel.arch.x86_64.constants;
import kernel.arch.x86_64.common;
import kernel.arch.x86_64.paging;
import kernel.arch.x86_64.registers;
import kernel.arch.x86_64.descriptors;
import kernel.arch.x86_64.screen;

version(arch_x86_64):

PageTable* arch_init()
{
    /*disable_interrupts();

    PageTable* pagetable = cast(PageTable*)(cr3 + KERNEL_VIRTUAL_BASE);

    setup_gdt();
    setup_tss();
    setup_interrupts();
    
    screen_mem = cast(byte*)(KERNEL_VIRTUAL_BASE + 0xB8000);
    clear_screen();
    
    return pagetable;*/
    
    return null;
}

void arch_setup()
{
    /*PageTable* pagetable = cast(PageTable*)(cr3 + KERNEL_VIRTUAL_BASE);

    for(size_t i=0; i<1024*FRAME_SIZE; i+=FRAME_SIZE)
    {
        pagetable.unmap(i);
    }
    
    root.addHandler("dev.pit", EventHandler(0, &pit_handler));*/
}
