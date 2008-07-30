/**
 * Bit array utility for easier bit-twiddling
 *
 * Based on std.bitarray (Phobos, Walter Bright) and tango.core.BitArray (Tango, Sean Kelly and Walter Bright)
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
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
        return cast(bool)bt(cast(uint*)this, i);
    }
    
    void opIndexAssign(bool b, size_t i)
    {
        if(b)
            bts(cast(uint*)this, i);
        else
            btr(cast(uint*)this, i);
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
    
    void opSliceAssign(size_t value, size_t x, size_t y)
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
}
