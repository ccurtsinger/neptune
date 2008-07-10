/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.core;
import kernel.event;
import kernel.process;

import kernel.spec.multiboot;
import kernel.spec.elf;

import kernel.arch.setup;
import kernel.arch.paging;
import kernel.arch.constants;
import kernel.arch.common;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.heap;

import std.stdio;
import std.string;

extern(C) void _main(MultibootInfo* multiboot, uint magic)
{
    PageTable* pagetable = arch_init();
    
    // Initialize the physical memory allocator
    p_init();
    
    multiboot.initMemory();

    // Initialize the base address space
    addr = AddressSpace(pagetable, 0, 0, multiboot.getKernelMemoryRange().aligned(FRAME_SIZE).size);
    
    // Initialize the kernel heap
    m_init(&addr, ZoneType.KERNEL_HEAP);    

    foreach(m, mod; multiboot.getModules())
    {
        ElfHeader* elf = cast(ElfHeader*)mod.data;

        if(elf.valid())
        {
            writefln("Loaded ELF module %s", mod.string);
            
            // Mark physical memory used by modules as used
            size_t base = mod.base;
            size_t top = base + mod.size;
            
            base -= base % FRAME_SIZE;
            size_t offset = top % FRAME_SIZE;
            
            if(offset != 0)
                top += FRAME_SIZE - offset;
            
            for(size_t i=base; i<top; i+=FRAME_SIZE)
            {
                p_set(i);
            }
            
            // Create a process for this module
            processes ~= Process(cast(ElfHeader*)(cast(size_t)elf + KERNEL_VIRTUAL_BASE));
        }
    }
    
    arch_setup();
    
    enable_interrupts();
    
    for(;;){}
}

Process[] processes;
size_t current = size_t.max;

extern(C) void task_switch(Context* context)
{
    if(current == size_t.max)
    {
        current = 0;
        load_page_table(processes[current].pagetable);
        set_kernel_entry_stack(processes[current].k_stack);
        *context = processes[current].context;
    }
    else
    {
        processes[current].context = *context;
        
        current++;
        
        if(current >= processes.length)
            current = 0;
        
        load_page_table(processes[current].pagetable);
        set_kernel_entry_stack(processes[current].k_stack);
        *context = processes[current].context;
    }
}
