/**
 * Array support functions for the D language
 *
 * Based on code in Phobos (Walter Bright) and Tango (Sean Kelly)
 *
 * Authors: Walter Bright, Sean Kelly, Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 *
 * Copyright: 2004-2007 Digital Mars, www.digitalmars.com
 */

/*
 *  Copyright (C) 2004-2007 by Digital Mars, www.digitalmars.com
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

module array;

import error;
import std.stdlib;
import std.stdarg;
import std.mem;

struct Array
{
    size_t length;
    byte*  data;
}

/**
 * Called when array bounds are exceeded
 *
 * Params:
 *  file = name of the file where the error occurred
 *  line = line in the file where the error occurred
 */
extern (C) void _d_array_bounds(char[] file, uint line)
{
    onError("array index out of bounds", file, line);
}

/**
 * Copy one array to another
 *
 * Params:
 *  size = size of an element in both arrays
 *  from = array to copy from
 *  to = array to copy to
 *
 * Returns: The destination array
 */
extern (C) byte[] _d_arraycopy(size_t size, byte[] from, byte[] to)
{
    if (to.length != from.length)
    {
    	onError("lengths don't match for array copy");
        //throw new Exception("lengths don't match for array copy");
    }
    else if(cast(byte*)to   + to.length   * size <= cast(byte*)from ||
			cast(byte*)from + from.length * size <= cast(byte*)to)
    {
        memcpy(to.ptr, from.ptr, to.length * size);
    }
    else
    {
        onError("overlapping array copy");
        //throw new Exception("overlapping array copy");
    }

    return to;
}

/**
 * Concatenate two array
 *
 * Params:
 *  ti = TypeInfo for the array elements
 *  px = pointer to the first array
 *  y = the second array
 *
 * Returns: the concatenated array
 */
extern (C) Array _d_arrayappendT(TypeInfo ti, Array *px, byte[] y)
{
    auto sizeelem = ti.next.tsize();
    auto length = px.length;
    auto newlength = length + y.length;
    auto newsize = newlength * sizeelem;

	byte* newdata = cast(byte*)malloc(newCapacity(newlength, sizeelem) + 1);

	memcpy(newdata, px.data, length * sizeelem);
	px.data = newdata;

    px.length = newlength;
    memcpy(px.data + length * sizeelem, y.ptr, y.length * sizeelem);
    return *px;
}

/**
 * Calculate the new capacity of an array, given a minimum length and element size
 *
 * Becomes non-trivial when larger-than-needed blocks may be allocated
 *
 * Params:
 *  newlength = the new array length
 *  size = the size of each element
 *
 * Returns: the capacity that will be allocated
 */
size_t newCapacity(size_t newlength, size_t size)
{
    return newlength * size;
}

/**
 * Append an element to an array
 *
 * Params:
 *  ti = TypeInfo for the array elements
 *  x = base array
 *  argp = pointer to the element to append
 *
 * Returns: the newly appended-to array
 */
extern (C) byte[] _d_arrayappendcTp(TypeInfo ti, inout byte[] x, void *argp)
{
    auto sizeelem = ti.next.tsize();            // array element size
    auto length = x.length;
    auto newlength = length + 1;
    auto newsize = newlength * sizeelem;
    size_t cap;

	byte* newdata;

	cap = newCapacity(newlength, sizeelem);
	
	assert(cap >= newlength * sizeelem);

	newdata = cast(byte *)malloc(cap + 1);
	
	memcpy(newdata, x.ptr, length * sizeelem);
	
	(cast(void**)(&x))[1] = newdata;

    *cast(size_t *)&x = newlength;
    
    byte* b = cast(byte*)x.ptr;
    
    memcpy(&(b[length*sizeelem]), argp, sizeelem);
    
    assert((cast(size_t)x.ptr & 15) == 0);

    return x;
}

/**
 * Concatenate a variable number of arrays
 *
 * Params:
 *  ti = TypeInfo for the array elements
 *  n = number of arrays to concatenate
 *  ... = list of arrays to concatenate
 *
 * Returns: The resulting array
 */
extern (C) byte[] _d_arraycatnT(TypeInfo ti, uint n, ...)
{
    System.output.writef("_d_arraycatnT(%s, %u, ...)", ti.toString(), n).newline;
    
    void* a;
    byte[] b;
    size_t length;
    va_list va = void;
    size_t size = ti.next.tsize();

    va_start!(typeof(n))(va, n);

    for (uint i = 0; i < n; i++)
    {
        b = va_arg!(typeof(b))(va);
        length += b.length;
    }
    
    if (!length)
    {
        return null;
    }

    a = malloc(length * size);

    va_start!(typeof(n))(va, n);

    uint j = 0;
    
    for (uint i = 0; i < n; i++)
    {
        b = va_arg!(typeof(b))(va);
        
        if (b.length)
        {
            memcpy(a + j, b.ptr, b.length * size);
            j += b.length * size;
        }
    }

    return (cast(byte*)a)[0..length];
}

/**
 * Helper function for casting dynamic arrays
 *
 * Params:
 *  tsize = size of elements in the target array
 *  fsize = size of elements in the source array
 *  a = array to cast
 *
 * Returns: array a with new length set
 */
extern (C) void[] _d_arraycast(size_t tsize, size_t fsize, void[] a)
{
    auto length = a.length;

    auto nbytes = length * fsize;
    
    if (nbytes % tsize != 0)
    {
        onError("array cast misalignment");
        //throw new Exception("array cast misalignment");
    }
    
    length = nbytes / tsize;
    
    *cast(size_t *)&a = length; // jam new length
    
    return a;
}
