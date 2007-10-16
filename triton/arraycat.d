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

private
{
    //import tango.stdc.string;
    //debug import tango.stdc.stdio;

    import mem.util;
    import dev.screen;
}

extern (C):

byte[] _d_arraycopy(size_t size, byte[] from, byte[] to)
{
    if (to.length != from.length)
    {
        print("Exception: lengths don't match for array copy");
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
        print("Exception: overlapping array copy");
        for(;;){}
        //throw new Exception("overlapping array copy");
    }

    return to;
}
