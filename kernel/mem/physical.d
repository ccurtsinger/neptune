/**
 * Physical memory allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.physical;

import kernel.arch.constants;

import std.bitarray;

BitArray bits;
uint[PHYSICAL_MEMORY_MAX / (32 * FRAME_SIZE) + 1] available;

void p_init()
{
    for(size_t index = 0; index < available.length; index++)
    {
        available[index] = uint.max;
    }
}

bool p_state(size_t address)
{
    address >>= FRAME_BITS;
    return !bits[address];
}

void p_set(size_t address)
{
    address >>= FRAME_BITS;
    bits[address] = true;
}

void p_free(size_t address)
{
    address >>= FRAME_BITS;
    bits[address] = false;
}

size_t p_alloc()
{
    // TODO: Synchronize or make atomic
    size_t p = bits.setFirstCleared(available.sizeof * 8);
    
    if(p < available.sizeof * 8)
        return p<<FRAME_BITS;
    
    // TODO: raise event to invoke swapping to disk or page collection
    assert(false, "Out of physical memory");
}
