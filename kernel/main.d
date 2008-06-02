/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.arch.native;
import kernel.spec.multiboot;

import std.port;
import std.mem;
import std.stdio;
import std.bit;

PhysicalAllocator phys;

extern(C) void _main(MultibootInfo* multiboot, uint magic)
{
    startup();
    
    // Initialize the physical memory allocator
    phys.init();
    
    // Free memory from the multiboot memory map
    foreach(mem; multiboot.getMemoryMap())
    {
        // If memory region is available
        if(mem.type == 1)
        {
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
    
    for(;;){}
}

struct PhysicalAllocator
{
    // Allocate enough bits for the entire address space
    uint[size_t.max / (32 * FRAME_SIZE) + 1] available;
    
    /**
     * Mark all pages as unavailable
     */
    void init()
    {
        for(size_t index = 0; index < available.length; index++)
        {
            available[index] = uint.max;
        }
    }
    
    /**
     * Check if a page is available
     */
    bool check(size_t paddr)
    {
        paddr >>= FRAME_BITS;
        
        size_t bit = paddr % 32;
        size_t index = (paddr - bit) / 32;
        
        return !bt(&(available[index]), bit);
    }
    
    /**
     * Mark a page as available
     */
    void free(size_t paddr)
    {
        paddr >>= FRAME_BITS;
        
        size_t bit = paddr % 32;
        size_t index = (paddr - bit) / 32;
        
        btr(&(available[index]), bit);
    }
    
    /**
     * Mark and return the corresponding physical address
     * for the next available page
     */
    size_t allocate()
    {
        for(size_t index = 0; index < available.length; index++)
        {
            uint b = available[index];
            
            if(b < uint.max)
            {
                // TODO: Synchronize or make atomic
                size_t bit = bsf(~b);
                bts(&(available[index]), bit);
                
                return (32 * index + bit) << FRAME_BITS;
            }
        }
        
        // TODO: raise event to invoke swapping to disk or page collection
        assert(false, "Out of physical memory");
    }
}
