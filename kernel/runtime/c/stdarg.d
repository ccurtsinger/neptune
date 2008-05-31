/**
 * C's stdarg.h
 * 
 * Derived from copyrighted work by Walter Bright (www.digitalmars.com),
 * Hauke Duden, and David Friedman
 *
 * Copyright: 2008 The Neptune Project
 */

/* This is for use with extern(C) variable argument lists. */

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
 
/* NOTE: This file has been patched from the original DMD distribution to
   work with the GDC compiler.

   Modified by David Friedman, September 2004
*/

module c.stdarg;

version (GNU) {
    private import gcc.builtins;
    alias __builtin_va_list va_list;
    alias __builtin_va_end va_end;
    alias __builtin_va_copy va_copy;

    // The va_start and va_arg template functions are magically
    // handled by the compiler.
} else {

    alias void* va_list;

    void va_end(va_list ap)
    {

    }

    void va_copy(out va_list dest, va_list src)
    {
        static if ( is( dest T == T[1]) ) {
        dest[0] = src[0];
        } else {
        dest = src;
        }
    }

}

template va_start(T)
{
    void va_start(out va_list ap, inout T parmn)
    {
	/*
	ap = cast(va_list)(cast(void*)&parmn + ((T.sizeof + int.sizeof - 1) & ~(int.sizeof - 1)));
	*/
    }
}

template va_arg(T)
{
    T va_arg(inout va_list ap)
    {
	/*
	T arg = *cast(T*)ap;
	ap = cast(va_list)(cast(void*)ap + ((T.sizeof + int.sizeof - 1) & ~(int.sizeof - 1)));
	return arg;
	*/
	T t;
	return t;
    }
}

