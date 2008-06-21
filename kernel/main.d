/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.core;
import kernel.event;
import kernel.spec.multiboot;
import kernel.arch.native;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.heap;

import std.stdio;
import std.string;

extern(C) void _main(MultibootInfo* multiboot, uint magic)
{
    PageTable* pagetable = startup();
    
    // Initialize the physical memory allocator
    phys.init();
    
    size_t lost = 0;
    
    // Free memory from the multiboot memory map
    foreach(mem; multiboot.getMemoryMap())
    {
        // If memory region is available
        if(mem.type == 1)
        {
            // TODO: Determine if the page is occupied by the kernel binary, and if so, don't free it
            
            // Determine the offset into a page frame of the base
            size_t offset = mem.base % FRAME_SIZE;
            
            // If the boundary isn't page-aligned, bump up to the next page
            if(offset != 0)
                offset = FRAME_SIZE - offset;
            
            // Loop over all complete pages in the set
            for(size_t i=offset; i<=mem.size && i+FRAME_SIZE <= mem.size; i+=FRAME_SIZE)
            {
                phys.free(mem.base + i);
            }
        }
    }
    
    // Initialize the base address space
    addr = AddressSpace(pagetable, 0, FRAME_SIZE);
    
    // Initialize the kernel heap
    heap = HeapAllocator(&phys, &addr, ZoneType.KERNEL_HEAP);
    
    root.addHandler("test", EventHandler(0, &handler1));
    root.addHandler("test.a", EventHandler(0, &handler2));
    root.addHandler("test.b", EventHandler(0, &handler3));
    root.addHandler("test.a.1", EventHandler(0, &handler4));

    root.raiseEvent("test.a.1");
    
    for(;;){}
}

void handler1(char[] domain)
{
    writefln("handler1: %s", domain);
}

void handler2(char[] domain)
{
    writefln("handler2: %s", domain);
}

void handler3(char[] domain)
{
    writefln("handler3: %s", domain);
}

void handler4(char[] domain)
{
    writefln("handler4: %s", domain);
}
