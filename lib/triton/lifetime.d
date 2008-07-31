/**
 * Object lifetime support code
 *
 * Based on code in Phobos (Walter Bright) and Tango (Sean Kelly)
 *
 * Copyright: 2008 The Neptune Project
 */

/*
 * Copyright: Copyright (C) 2004-2008 Digital Mars, www.digitalmars.com.
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

import std.mem;

import array;

private extern (D) alias void (*fp_t)(Object);

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
    void* p = m_alloc(ci.init.length);
    
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
        
        Object o = cast(Object)(*p - pi.offset);

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
        ClassInfo **pc = cast(ClassInfo **)*p;
        
        if (*pc)
        {
            ClassInfo c = **pc;

            rt_finalize(cast(void*) *p);

            if (c.deallocator)
            {
                fp_t fp = cast(fp_t)c.deallocator;
                (*fp)(*p); // call deallocator
                *p = null;
                return;
            }
        }
        else
            rt_finalize(cast(void*) *p);

        m_free(cast(void*) *p);
        
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

        result.data = cast(byte*)m_alloc(size+1);

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
    auto size = ti.next.tsize();
    auto init = ti.next.init();
    auto isize = init.length;
    
    Array result = _d_newarrayT(ti, length);
    
    for(size_t u=0; u<size; u+=isize)
    {
        memcpy(result.data + u, init.ptr, isize);
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
            m_free(p.data);
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
        m_free(*p);
        *p = null;
    }
}

/**
 * Call the runtime class finalizer
 *
 * Params:
 *  p = pointer to the object to finalize
 */
extern (C) void _d_callfinalizer(void* p)
{
    rt_finalize(p);
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
			
			
			/*if (getMonitor(cast(Object)p) !is null) // if monitor is not null
			{
				_d_monitordelete(cast(Object)p, det);
			}*/
			
			
            *pc = null;
        }
    }
}
