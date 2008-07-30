/**
 * Bit testing and setting operations
 * 
 * Derived from copyrighted work by Walter Bright (www.digitalmars.com)
 *
 * Copyright: 2008 The Neptune Project
 */

/*
 *  Copyright (C) 2004-2008 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

module std.bit;

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
ptrdiff_t bsf(size_t v)
{
	ptrdiff_t i;

	asm
	{
	    "bsf %[value], %[index]" : [index] "=r" i : [value] "r" v;
	}

	return i;
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
ptrdiff_t bsr(size_t v)
{
	ptrdiff_t i;

	asm
	{
	    "bsr %[value], %[index]" : [index] "=r" i : [value] "r" v;
	}

	return i;
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
bool bt(uint *p, uint bitnum)
{
    return (p[bitnum / (uint.sizeof*8)] & (1<<(bitnum & ((uint.sizeof*8)-1)))) ? true : false;
}

/**
 * Tests and complements a bit
 *
 * Params:
 *  p = pointer to the value to operate on
 *  bitnum = bit index to operate on
 */
bool btc(uint *p, uint bitnum)
{
    uint * q = p + (bitnum / (uint.sizeof*8));
    uint mask = 1 << (bitnum & ((uint.sizeof*8) - 1));
    int result = *q & mask;
    *q ^= mask;
    return result ? true : false;
}

/**
 * Tests and resets (sets to 0) a bit
 *
 * Params:
 *  p = pointer to the value to operate on
 *  bitnum = bit index to operate on
 */
bool btr(uint *p, uint bitnum)
{
    uint * q = p + (bitnum / (uint.sizeof*8));
    uint mask = 1 << (bitnum & ((uint.sizeof*8) - 1));
    int result = *q & mask;
    *q &= ~mask;
    return result ? true : false;
}

/**
 * Test and set a bit
 *
 * Params:
 *  p = pointer to the value to operate on
 *  bitnum = bit index to operate on
 */
bool bts(uint *p, uint bitnum)
{
    uint * q = p + (bitnum / (uint.sizeof*8));
    uint mask = 1 << (bitnum & ((uint.sizeof*8) - 1));
    int result = *q & mask;
    *q |= mask;
    return result ? true : false;
}
