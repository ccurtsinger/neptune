/**
 * Physical memory allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.physical;

import kernel.arch.constants;

import std.bitarray;

struct PhysicalAllocator
{
    // Allocate enough bits for the entire address space
    union
    {
        uint[PHYSICAL_MEMORY_MAX / (32 * FRAME_SIZE) + 1] available;
        BitArray bits;
    }
    
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

        return !bits[paddr];
    }
    
    /**
     * Mark a page as available
     */
    void free(size_t paddr)
    {
        paddr >>= FRAME_BITS;
        
        bits[paddr] = false;
    }
    
    /**
     * Mark a page as in use
     */
    void set(size_t paddr)
    {
        paddr >>= FRAME_BITS;
        
        bits[paddr] = true;
    }
    
    /**
     * Mark and return the corresponding physical address
     * for the next available page
     */
    size_t allocate()
    {
        // TODO: Synchronize or make atomic
        size_t p = bits.setFirstCleared(available.sizeof * 8);
        
        if(p < available.sizeof * 8)
            return p<<FRAME_BITS;
        
        // TODO: raise event to invoke swapping to disk or page collection
        assert(false, "Out of physical memory");
    }
}
