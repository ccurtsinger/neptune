/**
 * Bit testing and setting operations (non-atomic)
 * 
 * Based on the implemented bit operations in std.intrinsic
 * written by Walter Bright.
 *
 * Authors: Walter Bright, Charlie Curtsinger
 * Date: October 29th, 2007
 * Version: 0.1a
 */
module std.bits;

/**
 * Scan for the first set bit
 *
 * Params:
 *  v = value to scan through
 *
 * Returns:
 *	The bit number of the first bit set
 *	The return value is undefined if v is zero
 */
int bsf(uint v)
{
	uint m = 1;
	
	uint i;
	
	for (i = 0; i < 64; i++,m<<=1) 
	{
	    if (v&m)
	    {
            return i;
	    }
	}
	
	return i; // supposed to be undefined
}

/**
 * Scan for the last set bit
 * 
 * Params:
 *  v = value to scan through
 *
 * Returns
 *  The bit number for the last bit set
 *  The return value is undefined if v is zero
 */
int bsr(uint v)
{
    uint m = 0x80000000;
    uint i;
    
    for (i = 64; i ; i--,m>>>=1) 
    {
        if (v&m)
        {
            return i-1;
        }
    }
    
    return i; // supposed to be undefined
}

/**
 * Test a bit
 *
 * Params:
 *  p = pointer to the value to test bit in
 *  bitnum = index of the bit to test
 *
 * Returns: the value of the bit being tested
 */
int bt(uint *p, uint bitnum)
{
    return (p[bitnum / (uint.sizeof*8)] & (1<<(bitnum & ((uint.sizeof*8)-1)))) ? -1 : 0 ;
}

/**
 * Tests and complements a bit
 *
 * Params:
 *  p = pointer to the value to operate on
 *  bitnum = bit index to operate on
 */
int btc(uint *p, uint bitnum)
{
    uint * q = p + (bitnum / (uint.sizeof*8));
    uint mask = 1 << (bitnum & ((uint.sizeof*8) - 1));
    int result = *q & mask;
    *q ^= mask;
    return result ? -1 : 0;
}

/**
 * Tests and resets (sets to 0) a bit
 *
 * Params:
 *  p = pointer to the value to operate on
 *  bitnum = bit index to operate on
 */
int btr(uint *p, uint bitnum)
{
    uint * q = p + (bitnum / (uint.sizeof*8));
    uint mask = 1 << (bitnum & ((uint.sizeof*8) - 1));
    int result = *q & mask;
    *q &= ~mask;
    return result ? -1 : 0;
}

/**
 * Test and set a bit
 * 
 * Params:
 *  p = pointer to the value to operate on
 *  bitnum = bit index to operate on
 */
int bts(uint *p, uint bitnum)
{
    uint * q = p + (bitnum / (uint.sizeof*8));
    uint mask = 1 << (bitnum & ((uint.sizeof*8) - 1));
    int result = *q & mask;
    *q |= mask;
    return result ? -1 : 0;
}


/**
 * Swaps bytes in a 4 byte uint end-to-end, i.e. byte 0 becomes
	byte 3, byte 1 becomes byte 2, byte 2 becomes byte 1, byte 3
	becomes byte 0.
 */
uint bswap(uint v)
{
    return ((v&0xFF)<<24)|((v&0xFF00)<<8)|((v&0xFF0000)>>>8)|((v&0xFF000000)>>>24);
}
