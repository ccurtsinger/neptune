/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.core;
import kernel.spec.multiboot;
import kernel.arch.native;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.heap;

import std.stdio;

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
    
    addr = AddressSpace(pagetable, 0, FRAME_SIZE);
    
    heap = HeapAllocator(&phys, &addr, ZoneType.HEAP);
    
    void* a = heap.allocate(0x28);
    void* b = heap.allocate(0x28);
    void* c = heap.allocate(FRAME_SIZE);
    
    heap.free(b);
    heap.free(a);
    
    heap.show();
    
    for(;;){}
}
