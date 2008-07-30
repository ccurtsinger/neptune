/**
 * Bit array utility for easier bit-twiddling
 *
 * Copyright: 2008 The Neptune Project
 */

module std.bitarray;

import std.bit;

/**
 * Standard class for bit manipulation.  Differs from Phobos and Tango implementation in that
 * all bit manipulation is done in-place.
 *
 * This is implemented as a struct so it can be used to set up page tables and other memory-related
 * structures before dynamic memory is available.
 */
struct BitArray
{
    static BitArray* opCall(void* p)
    {
        return cast(BitArray*)p;
    }
    
    bool opIndex(size_t i)
    {
        size_t bit = i % 32;
        size_t index = (i - bit) / 32;
        
        uint* a = cast(uint*)this;
        
        return bt(&(a[index]), bit);
    }
    
    bool opIndexAssign(bool b, size_t i)
    {
        size_t bit = i % 32;
        size_t index = (i - bit) / 32;
        
        uint* a = cast(uint*)this;
        
        if(b)
            return bts(&(a[index]), bit);
        else
            return btr(&(a[index]), bit);
    }
    
    ulong opSlice(size_t x, size_t y)
    in
    {
        assert(y-x <= 64, "Cannot slice a BitArray into larger than 64 bit values");
    }
    body
    {
        if(x >= 64)
        {
            auto b = BitArray(cast(void*)(cast(ulong)this + 8));
            
            return (*b)[x-64..y-64];
        }
        else if(y > 64)
        {
            return opSlice(x, 64) | (opSlice(64, y) << (64 - x));
        }
        else
        {
            ulong value = *(cast(ulong*)this);
            
            if(y - x == ulong.sizeof*8)
                return value;
            
            value >>= x;
            
            value &= ~(ulong.max << (y-x));
            
            return value;
        }
    }
    
    void opSliceAssign(ulong value, size_t x, size_t y)
    {
        if(x >= 64)
        {
            auto b = BitArray(cast(void*)(cast(ulong)this + 8));
            
            (*b)[x-64..y-64] = value;
        }
        else if(y > 64)
        {
            opSliceAssign(value, x, 64);
            opSliceAssign(value >> (64 - x), 64, y);
        }
        else
        {
            ulong mask = ulong.max >> (ulong.sizeof*8 - (y - x));
            mask <<= x;
            mask = ~mask;
            
            // Mask now has all bits set, except those in x..y
            
            value <<= x;
            
            value &= ~mask;
            
            *(cast(ulong*)this) &= mask;
            *(cast(ulong*)this) |= value;
        }
    }
    
    size_t setFirstCleared(size_t limit)
    {
        uint* a = cast(uint*)this;
        
        for(size_t index = 0; index < limit; index++)
        {
            uint b = a[index];
            
            if(b < uint.max)
            {
                size_t bit = bsf(~b);
                bts(&(a[index]), bit);
                
                return 32 * index + bit;
            }
        }
        
        return limit;
    }
}
