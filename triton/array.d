/**
 * Part of the D programming language runtime library.
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

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 *
 *  Modified by Charlie Curtsinger <speal@devlime.com> for use with Neptune.
 */

import std.stdio;
import std.mem;

import std.stdlib;

extern (C):

void[] _d_arraycast(size_t tsize, size_t fsize, void[] a)
{
    auto length = a.length;
    auto nbytes = length * fsize;
    
    if (nbytes % tsize != 0)
    {
        assert(false, "array cast misalignment");
        //throw new Exception("array cast misalignment");
    }
    
    length = nbytes / tsize;
    *cast(size_t*)&a = length; // jam new length
    
    return a;
}

byte[] _d_arraycopy(size_t size, byte[] from, byte[] to)
{
    if (to.length != from.length)
    {
        write("Exception: lengths don't match for array copy");
        for(;;){}

        //throw new Exception("lengths don't match for array copy");
    }
    else if (cast(byte *)to + to.length * size <= cast(byte *)from ||
        cast(byte *)from + from.length * size <= cast(byte *)to)
    {
        memcpy(cast(byte *)to, cast(byte *)from, to.length * size);
    }
    else
    {
        write("Exception: overlapping array copy");
        
        ulong i = cast(ulong)from.ptr;
        
        while(i > 0)
        {
            ulong d = i%16;
            i -= d;
            i /= 16;
            
            if(d < 10)
                putc('0' + d);
            else
                putc('A' + (d - 10));
        }
        
        for(;;){}
        //throw new Exception("overlapping array copy");
    }

    return to;
}
