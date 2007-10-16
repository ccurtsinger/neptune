/**
 * Created by Charlie Curtsinger
 * October 15th, 2007
 *
 * Based on std.bitarray (Phobos, Walter Bright) and tango.core.BitArray (Tango, Sean Kelly and Walter Bright)
 */

module std.bitarray;

import std.intrinsic;

/**
 * Standard class for bit manipulation.  Differs from Phobos and Tango implementation in that
 * all bit manipulation is done in-place.
 */
struct BitArray
{
    size_t len;
    size_t off;
    uint* ptr;

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
     * Return the length of the bit array
     */
    size_t length()
    {
        return len;
    }

    /**
     * Resize the array (in-place) leaving existing data intact
     */
    void length(size_t newlen)
    {
        len = newlen;
    }

    /**
     * Support for array indexing
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
     * Array slicing support
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
     * Array slice assignment support
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
}
