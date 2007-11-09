/**
 * Object lifetime support code
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
 * This module contains all functions related to an object's lifetime:
 * allocation, resizing, deallocation, and finalization.
 *
 * Copyright: Copyright (C) 2004-2007 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:
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
 * Authors:   Walter Bright, Sean Kelly
 */

module lifetime;

import std.stdlib;
import std.stdmem;

import array;

private
{
    private extern (D) alias void (*fp_t)(Object);
}

/**
 * Allocate and initialize a new object
 *
 * Params:
 *  ci = ClassInfo for the new class
 *
 * Returns: allocated an initialized object
 */
extern (C) Object _d_newclass(ClassInfo ci)
{
    void* p = System.memory.heap.allocate(ci.init.length);
    
    (cast(byte*) p)[0 .. ci.init.length] = ci.init[];
    
    return cast(Object)p;
}

/**
 * Locate an interface and perform the object delete operation on it
 *
 * Params:
 *  p = pointer to the interface pointer
 */
extern (C) void _d_delinterface(void** p)
{
    if (*p)
    {
        Interface* pi = **cast(Interface***)*p;
        
        Object o  = cast(Object)(*p - pi.offset);

        _d_delclass(&o);
        
        *p = null;
    }
}

/**
 * Deconstruct and free an object
 *
 * Params:
 *  p = pointer to the object to delete
 */
extern (C) void _d_delclass(Object* p)
{
    if (*p)
    {
        rt_finalize(cast(void*) *p);

        ClassInfo** pc = cast(ClassInfo**)*p;
        
        if (*pc)
        {
            ClassInfo c = **pc;

            if (c.deallocator)
            {
                fp_t fp = cast(fp_t)c.deallocator;
                
                (*fp)(*p); // call deallocator
                
                *p = null;
                
                return;
            }
        }
        
        System.memory.heap.free(p);
        
        *p = null;
    }
}

/**
 * Allocate a new array (elements initialized to 0)
 *
 * Params:
 *  ti = TypeInfo for the array elements
 *  length = length of the array
 *
 * Returns: the initialized array
 */
extern (C) Array _d_newarrayT(TypeInfo ti, size_t length)
{
    Array result;
    auto size = ti.next.tsize();                // array element size

    if (length != 0 && size != 0)
	{
        result.length = length;
        size *= length;

        result.data = cast(byte*)System.memory.heap.allocate(size+1);

        memset(result.data, 0, size);
    }
    
    return result;
}

/**
 * Allocate and initialize (to non-zero value) a new array
 *
 * Params:
 *  ti = TypeInfo for the array elements
 *  length = length of the array
 *
 * Returns: the initialized array
 */
extern (C) Array _d_newarrayiT(TypeInfo ti, size_t length)
{
    Array result;
    auto size = ti.next.tsize(); // array element size

    if (length != 0 && size != 0)
    {
        auto initializer = ti.next.init();
        auto isize = initializer.length;
        auto q = initializer.ptr;

        size *= length;

        auto p = cast(byte*)System.memory.heap.allocate(size+1);

        if (isize == 1)
        {
            memset(p, *cast(ubyte*)q, size);
        }
        else if (isize == int.sizeof)
        {
            int init = *cast(int*)q;
            size /= int.sizeof;

            for (size_t u = 0; u < size; u++)
            {
                (cast(int*)p)[u] = init;
            }
        }
        else
        {
            for (size_t u = 0; u < size; u += isize)
            {
                memcpy(p + u, q, isize);
            }
        }
        result.length = length;
        result.data = cast(byte*) p;
    }

    return result;
}

/**
 * Free a dynamically allocated array
 *
 * Params:
 *  p = pointer to the array
 */
extern (C) void _d_delarray(Array *p)
{
    if (p)
    {
        assert(!p.length || p.data);

        if (p.data)
        {
            System.memory.heap.free(p.data);
        }
        
        p.data = null;
        p.length = 0;
    }
}

/**
 * Free a dynamically allocated memory region
 *
 * Params:
 *  p = pointer to the memory pointer
 */
extern (C) void _d_delmemory(void** p)
{
    if (*p)
    {
        System.memory.heap.free(*p);
        *p = null;
    }
}

/**
 * Call an object and all of its parent objects' deconstructors
 *
 * Params:
 *  p = pointer to the object
 *  det = true if deconstructors should be called
 */
extern (C) void rt_finalize(void* p, bool det = true)
{
    if (p)
    {
        ClassInfo** pc = cast(ClassInfo**)p;

        if (*pc)
        {
            ClassInfo c = **pc;

			if (det)
			{
				do
				{
					if (c.destructor)
					{
						fp_t fp = cast(fp_t)c.destructor;
						(*fp)(cast(Object)p); // call destructor
					}
					c = c.base;
				} while (c);
			}
			
			/*
			if ((cast(void**)p)[1]) // if monitor is not null
			{
				_d_monitordelete(cast(Object)p, det);
			}
			*/
			
            *pc = null;
        }
    }
}
