/**
 * Array support functions for the D language
 *
 * Based on code in Phobos (Walter Bright) and Tango (Sean Kelly)
 *
 * Authors: Walter Bright, Sean Kelly, Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2004-2008 Digital Mars, www.digitalmars.com
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

module array;

import std.mem;

struct Array
{
    size_t length;
    byte*  data;
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
    assert(to.length == from.length, "lengths don't match for array copy");
    
    assert(cast(byte*)to   + to.length   * size <= cast(byte*)from ||
			cast(byte*)from + from.length * size <= cast(byte*)to,
			"overlapping array copy");
    
    memcpy(to.ptr, from.ptr, to.length * size);
   
    return to;
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
    
    assert(nbytes % tsize == 0, "array cast misalignment");
    
    length = nbytes / tsize;
    
    *cast(size_t *)&a = length; // jam new length
    
    return a;
}
