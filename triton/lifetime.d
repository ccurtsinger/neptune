/**
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


private
{
    //import tango.stdc.stdlib;
    //import tango.stdc.string;
    import std.stdarg;
    //debug(PRINTF) import tango.stdc.stdio;
}

import boot.kernel : heap;
import mem.util;

private
{
    /*enum BlkAttr : uint
    {
        FINALIZE = 0b0000_0001,
        NO_SCAN  = 0b0000_0010,
        NO_MOVE  = 0b0000_0100,
        ALL_BITS = 0b1111_1111
    }

    extern (C) uint gc_getAttr( void* p );
    extern (C) uint gc_setAttr( void* p, uint a );
    extern (C) uint gc_clrAttr( void* p, uint a );

    extern (C) void*  gc_malloc( size_t sz, uint ba = 0 );
    extern (C) void*  gc_calloc( size_t sz, uint ba = 0 );
    extern (C) size_t gc_extend( void* p, size_t mx, size_t sz );
    extern (C) void   gc_free( void* p );

    extern (C) size_t gc_sizeOf( void* p );

    extern (C) bool onCollectResource( Object o );*/
    extern (C) void onFinalizeError( ClassInfo c, Exception e );
    extern (C) void onOutOfMemoryError();

    extern (C) void _d_monitordelete(Object h, bool det = true);

    enum
    {
        PAGESIZE = 4096
    }
}


/**
 *
 */
extern (C) Object _d_newclass(ClassInfo ci)
{
    void* p;

    debug(PRINTF) printf("_d_newclass(ci = %p, %s)\n", ci, cast(char *)ci.name);
    /*if (ci.flags & 1) // if COM object
    {
        p = tango.stdc.stdlib.malloc(ci.init.length);
        if (!p)
            onOutOfMemoryError();
    }
    else
    {
        p = gc_malloc(ci.init.length,
                      BlkAttr.FINALIZE | (ci.flags & 2 ? BlkAttr.NO_SCAN : 0));
        debug(PRINTF) printf(" p = %p\n", p);
    }*/

    // Allocate the necessary memory
    p = heap.allocate(ci.init.length);

    debug(PRINTF)
    {
        printf("p = %p\n", p);
        printf("ci = %p, ci.init = %p, len = %d\n", ci, ci.init, ci.init.length);
        printf("vptr = %p\n", *cast(void**) ci.init);
        printf("vtbl[0] = %p\n", (*cast(void***) ci.init)[0]);
        printf("vtbl[1] = %p\n", (*cast(void***) ci.init)[1]);
        printf("init[0] = %x\n", (cast(uint*) ci.init)[0]);
        printf("init[1] = %x\n", (cast(uint*) ci.init)[1]);
        printf("init[2] = %x\n", (cast(uint*) ci.init)[2]);
        printf("init[3] = %x\n", (cast(uint*) ci.init)[3]);
        printf("init[4] = %x\n", (cast(uint*) ci.init)[4]);
    }

    // initialize it
    (cast(byte*) p)[0 .. ci.init.length] = ci.init[];

    debug(PRINTF) printf("initialization done\n");
    return cast(Object) p;
}


/**
 *
 */
extern (C) void _d_delinterface(void** p)
{
    if (*p)
    {
        Interface* pi = **cast(Interface ***)*p;
        Object     o  = cast(Object)(*p - pi.offset);

        _d_delclass(&o);
        *p = null;
    }
}


// used for deletion
private extern (D) alias void (*fp_t)(Object);


/**
 *
 */
extern (C) void _d_delclass(Object* p)
{
    if (*p)
    {
        debug(PRINTF) printf("_d_delclass(%p)\n", *p);

        rt_finalize(cast(void*) *p);

        ClassInfo **pc = cast(ClassInfo **)*p;
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
        //gc_free(cast(void*) *p);
        heap.free(cast(void*) *p);
        *p = null;
    }
}


/**
 * Allocate a new array of length elements.
 * ti is the type of the resulting array, or pointer to element.
 * (For when the array is initialized to 0)
 */
extern (C) Array _d_newarrayT(TypeInfo ti, size_t length)
{
    Array result;
    auto size = ti.next.tsize();                // array element size

    debug(PRINTF) printf("_d_newarrayT(length = x%x, size = %d)\n", length, size);
    if (length == 0 || size == 0)
        {}
    else
    {
        result.length = length;
        size *= length;

        //result.data = cast(byte*) gc_malloc(size + 1, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0);
        result.data = cast(byte*)heap.allocate(size+1);

        memset(result.data, 0, size);
    }
    return result;
}

/**
 * For when the array has a non-zero initializer.
 */
extern (C) Array _d_newarrayiT(TypeInfo ti, size_t length)
{
    Array result;
    auto size = ti.next.tsize(); // array element size

    if (length == 0 || size == 0)
    {

    }
    else
    {
        auto initializer = ti.next.init();
        auto isize = initializer.length;
        auto q = initializer.ptr;

        size *= length;

        //auto p = gc_malloc(size + 1, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0);
        auto p = cast(byte*)heap.allocate(size+1);

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
 *
 */
struct Array
{
    size_t length;
    byte*  data;
}


/**
 *
 */
extern (C) void _d_delmemory(void* *p)
{
    if (*p)
    {
        //gc_free(*p);
        heap.free(*p);
        *p = null;
    }
}


/**
 *
 */
extern (C) void rt_finalize(void* p, bool det = true)
{
    debug(PRINTF) printf("rt_finalize(p = %p)\n", p);

    if (p) // not necessary if called from gc
    {
        ClassInfo** pc = cast(ClassInfo**)p;

        if (*pc)
        {
            ClassInfo c = **pc;

            try
            {
                if (det/* || onCollectResource(cast(Object)p)*/)
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
                if ((cast(void**)p)[1]) // if monitor is not null
                    _d_monitordelete(cast(Object)p, det);
            }
            catch (Exception e)
            {
                onFinalizeError(**pc, e);
            }
            finally
            {
                *pc = null; // zero vptr
            }
        }
    }
}


/**
 * Append y[] to array x[].
 * size is size of each array element.
 */
extern (C) Array _d_arrayappendT(TypeInfo ti, Array *px, byte[] y)
{
    auto sizeelem = ti.next.tsize();            // array element size
    //auto cap = gc_sizeOf(px.data);
    auto length = px.length;
    auto newlength = length + y.length;
    auto newsize = newlength * sizeelem;

    //if (newsize > cap)
    //{
        byte* newdata;

        /*if (cap >= PAGESIZE)
        {   // Try to extend in-place
            auto u = gc_extend(px.data, (newsize + 1) - cap, (newsize + 1) - cap);
            if (u)
            {
                goto L1;
            }
        }*/
        //newdata = cast(byte *)gc_malloc(newCapacity(newlength, sizeelem) + 1, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0);
        newdata = cast(byte *)heap.allocate(newCapacity(newlength, sizeelem) + 1);

        memcpy(newdata, px.data, length * sizeelem);
        px.data = newdata;
    //}
  L1:
    px.length = newlength;
    memcpy(px.data + length * sizeelem, y.ptr, y.length * sizeelem);
    return *px;
}


/**
 *
 */
size_t newCapacity(size_t newlength, size_t size)
{
    version(none)
    {
        size_t newcap = newlength * size;
    }
    else
    {
        /*
         * Better version by Dave Fladebo:
         * This uses an inverse logorithmic algorithm to pre-allocate a bit more
         * space for larger arrays.
         * - Arrays smaller than PAGESIZE bytes are left as-is, so for the most
         * common cases, memory allocation is 1 to 1. The small overhead added
         * doesn't affect small array perf. (it's virtually the same as
         * current).
         * - Larger arrays have some space pre-allocated.
         * - As the arrays grow, the relative pre-allocated space shrinks.
         * - The logorithmic algorithm allocates relatively more space for
         * mid-size arrays, making it very fast for medium arrays (for
         * mid-to-large arrays, this turns out to be quite a bit faster than the
         * equivalent realloc() code in C, on Linux at least. Small arrays are
         * just as fast as GCC).
         * - Perhaps most importantly, overall memory usage and stress on the GC
         * is decreased significantly for demanding environments.
         */
        size_t newcap = newlength * size;
        size_t newext = 0;

        /*if (newcap > PAGESIZE)
        {
            //double mult2 = 1.0 + (size / log10(pow(newcap * 2.0,2.0)));

            // redo above line using only integer math

            static int log2plus1(size_t c)
            {   int i;

                if (c == 0)
                    i = -1;
                else
                    for (i = 1; c >>= 1; i++)
                    {
                    }
                return i;
            }

            /* The following setting for mult sets how much bigger
             * the new size will be over what is actually needed.
             * 100 means the same size, more means proportionally more.
             * More means faster but more memory consumption.
             */
            //long mult = 100 + (1000L * size) / (6 * log2plus1(newcap));
            /*long mult = 100 + (1000L * size) / log2plus1(newcap);

            // testing shows 1.02 for large arrays is about the point of diminishing return
            if (mult < 102)
                mult = 102;
            newext = cast(size_t)((newcap * mult) / 100);
            newext -= newext % size;
            debug(PRINTF) printf("mult: %2.2f, alloc: %2.2f\n",mult/100.0,newext / cast(double)size);
        }*/
        newcap = newext > newcap ? newext : newcap;
        debug(PRINTF) printf("newcap = %d, newlength = %d, size = %d\n", newcap, newlength, size);
    }
    return newcap;
}


/**
 *
 */
extern (C) byte[] _d_arrayappendcTp(TypeInfo ti, inout byte[] x, void *argp)
{
    auto sizeelem = ti.next.tsize();            // array element size
    size_t cap;// = gc_sizeOf(x.ptr);
    auto length = x.length;
    auto newlength = length + 1;
    auto newsize = newlength * sizeelem;

    //assert(cap == 0 || length * sizeelem <= cap);

    debug(PRINTF) printf("_d_arrayappendc(sizeelem = %d, ptr = %p, length = %d, cap = %d)\n", sizeelem, x.ptr, x.length, cap);

    //if (newsize >= cap)
    //{
        byte* newdata;

        /*if (cap >= PAGESIZE)
        {   // Try to extend in-place
            auto u = gc_extend(x.ptr, (newsize + 1) - cap, (newsize + 1) - cap);
            if (u)
            {
                goto L1;
            }
        }*/
        debug(PRINTF) printf("_d_arrayappendc(size = %d, newlength = %d, cap = %d)\n", size, newlength, cap);
        cap = newCapacity(newlength, sizeelem);
        assert(cap >= newlength * sizeelem);
        //newdata = cast(byte *)gc_malloc(cap + 1, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0);
        newdata = cast(byte *)heap.allocate(cap + 1);
        memcpy(newdata, x.ptr, length * sizeelem);
        (cast(void**)(&x))[1] = newdata;
    //}
  L1:
    *cast(size_t *)&x = newlength;
    x.ptr[length * sizeelem .. newsize] = (cast(byte*)argp)[0 .. sizeelem];
    assert((cast(size_t)x.ptr & 15) == 0);
    //assert(gc_sizeOf(x.ptr) > x.length * sizeelem);
    return x;
}

/**
 *
 */
extern (C) byte[] _d_arraycatnT(TypeInfo ti, uint n, ...)
{
    void* a;
    size_t length;
    byte[]* p;
    uint i;
    byte[] b;
    va_list va = void;
    auto size = ti.next.tsize(); // array element size

    va_start!(typeof(n))(va, n);

    for (i = 0; i < n; i++)
    {
        b = va_arg!(typeof(b))(va);
        length += b.length;
    }
    if (!length)
        return null;

    //a = gc_malloc(length * size, !(ti.next.flags() & 1) ? BlkAttr.NO_SCAN : 0);
    a = heap.allocate(length * size);

    va_start!(typeof(n))(va, n);

    uint j = 0;
    for (i = 0; i < n; i++)
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
