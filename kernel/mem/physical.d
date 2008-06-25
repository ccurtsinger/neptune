/**
 * Physical memory allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.physical;

import kernel.arch.constants;

import std.bitarray;

struct PhysicalMemoryMap
{
    union
    {
        BitArray bits;
        uint[PHYSICAL_MEMORY_MAX / (32 * FRAME_SIZE) + 1] available;
    }
}

PhysicalMemoryMap pmem;

void p_init()
{
    for(size_t index = 0; index < pmem.available.length; index++)
    {
        pmem.available[index] = uint.max;
    }
}

bool p_state(size_t address)
{
    address >>= FRAME_BITS;
    return !pmem.bits[address];
}

void p_set(size_t address)
{
    address >>= FRAME_BITS;
    pmem.bits[address] = true;
}

void p_free(size_t address)
{
    address >>= FRAME_BITS;
    pmem.bits[address] = false;
}
import std.stdio;
size_t p_alloc()
{
    // TODO: Synchronize or make atomic
    size_t p = pmem.bits.setFirstCleared(pmem.available.sizeof * 8);
    
    if(p == 0xB8000>>FRAME_BITS)
    {
        writefln("Allocating %p", p<<FRAME_BITS);
        for(;;){}
    }
    
    if(p < pmem.available.sizeof * 8)
        return p<<FRAME_BITS;
    
    // TODO: raise event to invoke swapping to disk or page collection
    assert(false, "Out of physical memory");
}
