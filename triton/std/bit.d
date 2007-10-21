module std.bits;

/**
 * Based on the implemented bit operations in std.intrinsic
 * written by Walter Bright.
 */

/**
 * Scans the bits in v starting with bit 0, looking
 * for the first set bit.
 * Returns:
 *	The bit number of the first bit set.
 *	The return value is undefined if v is zero.
 */
int bsf(uint v)
{
	uint m = 1;
	uint i;
	for (i = 0; i < 32; i++,m<<=1) {
	    if (v&m)
		return i;
	}
	return i; // supposed to be undefined
}

int bsr(uint v)
{
    uint m = 0x80000000;
    uint i;
    for (i = 32; i ; i--,m>>>=1) {
	if (v&m)
	    return i-1;
    }
    return i; // supposed to be undefined
}

/**
 * Tests the bit.
 */
int bt(uint *p, uint bitnum)
{
    return (p[bitnum / (uint.sizeof*8)] & (1<<(bitnum & ((uint.sizeof*8)-1)))) ? -1 : 0 ;
}

/**
 * Tests and complements the bit.
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
 * Tests and resets (sets to 0) the bit.
 */
int btr(uint *p, uint bitnum)
{
    uint * q = p + (bitnum / (uint.sizeof*8));
    uint mask = 1 << (bitnum & ((uint.sizeof*8) - 1));
    int result = *q & mask;
    *q &= ~mask;
    return result ? -1 : 0;
}

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
