/**
 * Bit array utility for easier bit-twiddling
 *
 * Based on std.bitarray (Phobos, Walter Bright) and tango.core.BitArray (Tango, Sean Kelly and Walter Bright)
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
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
    size_t len;
    size_t off;
    uint* ptr;

    /**
     * Create a new bit array from a pointer
     *
     * Params:
     *  p = pointer to the value used in the bit array
     *  bits = number of bits in the array
     *  offset = number of bits to offset from the base of p
     *
     * Returns: the new bit array object
     */
    static BitArray opCall(void* p, size_t bits, size_t offset = 0)
    {
        BitArray b;
        b.init(p, bits, offset);
        return b;
    }

    /**
     * Initialize to a pointer, bit count, and base offset
     */
    void init(void* p, size_t bits, size_t offset = 0)
    {
        while(offset >= uint.sizeof * 8)
        {
            p += uint.sizeof;
            offset -= uint.sizeof * 8;
        }

        ptr = cast(uint*)p;
        len = bits;
        off = offset;
    }

    /**
     * Get the length of a bit array
     *
     * Returns: The number of bits in the array
     */
    size_t length()
    {
        return len;
    }

    /**
     * Resize the array (in-place) leaving existing data intact
     *
     * Params:
     *  newlen = new length of the array
     */
    void length(size_t newlen)
    {
        len = newlen;
    }

    /**
     * Support for array indexing
     *
     * Params:
     *  i = index to access
     *
     * Returns: state of the bit at i
     */
    bool opIndex(size_t i)
    in
    {
        assert(i < len);
    }
    body
    {
        return cast(bool)bt(ptr, i+off);
    }

    /**
     * Support for index assignment
     *
     * Params:
     *  b = new state for bit i
     *  i = bit index to set
     *
     * Returns: The new state of bit i
     */
    bool opIndexAssign(bool b, size_t i)
    in
    {
        assert(i < len);
    }
    body
    {
        if(b)
            bts(ptr, i+off);
        else
            btr(ptr, i+off);

        return b;
    }

    /**
     * Support for foreach loops
     *
     * Params:
     *  dg = operations to apply to each bit
     *
     * Returns: result of the last executed operation
     */
    int opApply(int delegate(inout bool) dg)
    {
        int result;

        for(size_t i=0; i<len; i++)
        {
            bool b = opIndex(i);
            result = dg(b);
            opIndexAssign(b, i);
            if(result)
                break;
        }
        
        return result;
    }

    /**
     * Support for foreach loops with test and assignment
     *
     * Params:
     *  dg = operation to apply to each bit
     *
     * Returns: result of the last executed operation
     */
    int opApply(int delegate(inout size_t, inout bool) dg)
    {
        int result;

        for(size_t i=0; i<len; i++)
        {
            bool b = opIndex(i);
            result = dg(i, b);
            opIndexAssign(b, i);
            if(result)
                break;
        }
        return result;
    }

    /**
     * Support for reverse foreach loops
     *
     * Params:
     *  dg = operation to apply to each bit
     * 
     * Returns: result of the last executed operations
     */
    int opApplyReverse(int delegate(inout bool) dg)
    {
        int result;

        for(size_t i=len; i>0; i--)
        {
            bool b = opIndex(i-1);
            result = dg(b);
            opIndexAssign(b, i-1);
            if(result)
                break;
        }
        return result;
    }
    
    /**
     * Support for reverse foreach loops with test and assignment
     *
     * Params:
     *  dg = operation to apply to each bit
     *
     * Returns: result of the last executed operation
     */
    int opApplyReverse(int delegate(inout size_t, inout bool) dg)
    {
        int result;

        for(size_t i=len; i>0; i--)
        {
            bool b = opIndex(i-1);
            i--;
            result = dg(i, b);
            i++;
            opIndexAssign(b, i-1);
            if(result)
                break;
        }
        return result;
    }

    /**
     * Array slicing support
     *
     * Params:
     *  x = base index to slice from (inclusive)
     *  y = limit index to slice to (exclusive)
     *
     * Returns: a BitArray of the sliced bit range
     */
    BitArray opSlice(size_t x, size_t y)
    in
    {
        assert(y > x);
    }
    body
    {
        BitArray ret;

        size_t newlen = y - x;
        ret.init(ptr, newlen, off+x);

        return ret;
    }

    /**
     * Array slice assignment to BitArray support
     *
     * Sets bits in the sliced section to corresponding bits in v
     *
     * Params:
     *  v = BitArray to assign from
     *  x = base index to slice from (inclusive)
     *  y = limit index to slice to (exclusive)
     */
    void opSliceAssign(BitArray v, size_t x, size_t y)
    in
    {
        assert(x >= 0);
        assert(y <= len);
        assert(y > x);
        assert(v.length() == y - x);
    }
    body
    {
        for(size_t i = x; i<y; i++)
        {
            opIndexAssign(v[i-x], i);
        }

    }

    /**
     * Array slice assignment to value support
     *
     * Sets bits in the sliced section to coresponding bits in v
     *
     * Params:
     *  v = value to assign from
     *  x = base index to slice from (inclusive)
     *  y = limit index to slice to (exclusive)
     */
    void opSliceAssign(ulong v, size_t x, size_t y)
    in
    {
        assert(x >= 0);
        assert(y <= len);
        assert(y > x);
    }
    body
    {
        auto b = BitArray(&v, 8*v.sizeof);

        for(size_t i = x; i<y; i++)
        {
            opIndexAssign(b[i-x], i);
        }
    }
}
