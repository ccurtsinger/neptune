/**
 * Object cast support functions for the D language
 *
 * Authors: Walter Bright, Sean Kelly, Charlie Curtsinger
 * Date: March 11th, 2008
 * Version: 0.4
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

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 *
 * Modified by Charlie Curtsinger for use with Triton
 */

extern (C):

/**
 * Dynamically cast an object to a class type
 *
 * Params:
 *  o = Object to cast
 *  c = ClassInfo for the cast target
 *
 * Returns: Cast object, or null if unsuccessful
 */
Object _d_dynamic_cast(Object o, ClassInfo c)
{   
	ClassInfo oc;
    size_t offset = 0;

    if (o)
    {
        oc = o.classinfo;
        
        if (_d_isbaseof(oc, c, offset))
        {
            o = cast(Object)(cast(void*)o + offset);
        }
        else
        {
            o = null;
        }
    }

    return o;
}

/**
 * Cast a pointer to an object
 *
 * If p is an object, return the object
 * If p is an interface, return the object implementing the interface
 * if p is null, return null
 * Other behavior is undefined
 *
 * Params;
 *  p = pointer to cast
 *
 * Returns: an object
 */
Object _d_toObject(void* p)
{   
    Object o;

    if(p)
    {
        o = cast(Object)p;
        ClassInfo oc = o.classinfo;
        Interface *pi = **cast(Interface ***)p;

        /* Interface.offset lines up with ClassInfo.name.ptr,
         * so we rely on pointers never being less than 64K,
         * and Objects never being greater.
         */
        if (pi.offset < 0x10000)
        {
            o = cast(Object)(p - pi.offset);
        }
    }
    
    return o;
}

/**
 * Cast an object to a particular class
 *
 * Params:
 *  p = pointer to the object to cast
 *  c = ClassInfo for the cast target
 *
 * Returns: The resulting Class, or null if unsuccessful
 */
Object _d_interface_cast(void* p, ClassInfo c)
{   
    Object o;

    if (p)
    {
        Interface *pi = **cast(Interface ***)p;

        o = cast(Object)(p - pi.offset);
        
        return _d_dynamic_cast(o, c);
    }
    
    return o;
}

/**
 * Determine if one Class is the base of another, and set the offset
 * of the interface if found
 *
 * Params:
 *  oc = The class being tested
 *  c = The potential base class
 *  offset = The offset of c in oc
 *
 * Returns: 1 is c is a base of oc, otherwise 0
 */
int _d_isbaseof(ClassInfo oc, ClassInfo c, inout size_t offset)
{   
    int i;

    if (oc is c)
        return 1;
    
    do
    {
        if (oc.base is c)
            return 1;
        
        for (i = 0; i < oc.interfaces.length; i++)
        {
            ClassInfo ic;

            ic = oc.interfaces[i].classinfo;
            
            if (ic is c || _d_isbaseof(ic, c, offset))
            {   
                offset = oc.interfaces[i].offset;
                return 1;
            }
        }
        
        oc = oc.base;
        
    } while (oc);
    
    return 0;
}
