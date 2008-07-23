/**
 * Physical memory allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.physical;

import kernel.arch.constants;
import kernel.lock;

import std.bitarray;

struct PhysicalMemoryMap
{
    union
    {
        private BitArray bits;
        private uint[PHYSICAL_MEMORY_MAX / (32 * FRAME_SIZE) + 1] available;
    }
    
    public void init()
    {
        for(size_t index = 0; index < available.length; index++)
        {
            available[index] = uint.max;
        }
    }
    
    public bool opIndex(size_t address)
    {
        address >>= FRAME_BITS;
        return bits[address];
    }
    
    public void opIndexAssign(bool state, size_t address)
    {
        address >>= FRAME_BITS;
        bits[address] = state;
    }
    
    public size_t allocate()
    {
        size_t p = bits.setFirstCleared(available.sizeof * 8);

        if(p < available.sizeof * 8)
            return p<<FRAME_BITS;
        else
            return size_t.max;
    }
}

PhysicalMemoryMap pmem;
Lock pmem_lock;

void p_init()
{
    pmem_lock.spinlock();
    scope(exit) pmem_lock.unlock();
    
    pmem.init();
}

bool p_state(size_t address)
{
    pmem_lock.spinlock();
    scope(exit) pmem_lock.unlock();
    
    return pmem[address];
}

void p_set(size_t address)
{
    pmem_lock.spinlock();
    scope(exit) pmem_lock.unlock();
    
    pmem[address] = true;
}

void p_free(size_t address)
{
    pmem_lock.spinlock();
    scope(exit) pmem_lock.unlock();

    pmem[address] = false;
}

size_t p_alloc()
{
    pmem_lock.spinlock();
    scope(exit) pmem_lock.unlock();
    
    size_t p = pmem.allocate();
    
    if(p != size_t.max)
        return p;
    
    // TODO: raise event to invoke swapping to disk or page collection
    assert(false, "Out of physical memory");
}
