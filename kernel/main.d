/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.arch.native;
import kernel.spec.multiboot;
import kernel.mem.physical;

import std.stdio;

PhysicalAllocator phys;
PageTable* pagetable;

PageTable* test;

extern(C) void _main(MultibootInfo* multiboot, uint magic)
{
    pagetable = startup();
    
    // Initialize the physical memory allocator
    phys.init();
    
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
    
    size_t p_test = phys.allocate();
    
    pagetable.map(0x10000000, p_test);
    
    test = cast(PageTable*)0x10000000;
    test.clear();
    test.map(0xC0000000, 0);
    
    load_page_table(p_test);
    
    writefln("Hello World!");
    
    for(;;){}
}
