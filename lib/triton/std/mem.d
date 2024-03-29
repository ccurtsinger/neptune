/**
 * Memory utility functions
 *
 * Copyright: 2008 The Neptune Project
 */

module std.mem;

/**
 * Set a memory range to a byte value
 *
 * Params:
 *  p = base of the memory to set
 *  value = value to set to
 *  size = number of bytes to set
 */
extern(C) void memset(void* p, ubyte value, size_t size)
{
    ulong i = cast(ulong)p;
    ubyte* b;

    while(i < cast(ulong)p+size)
    {
        b = cast(ubyte*)i;
        *b = value;
        i++;
    }
}

/**
 * Set a memory range to a short value
 *
 * Params:
 *  p = base of the memory to set
 *  value = value to set to
 *  size = number of bytes to set
 */
extern(C) void memsets(void* p, ushort value, size_t size)
{
    ulong i = cast(ulong)p;
    ushort* b;

    while(i < cast(ulong)p+size)
    {
        b = cast(ushort*)i;
        *b = value;
        i+=ushort.sizeof;
    }
}

/**
 * Copy size bytes from src to dest
 *
 * Params:
 *  dest = destination memory address
 *  src = source memory address
 *  size = size in bytes to copy
 */
extern(C) void memcpy(void* dest, void* src, size_t size)
{
    ubyte* d = cast(ubyte*)dest;
    ubyte* s = cast(ubyte*)src;

    for(ulong i=0; i<size; i++)
    {
        d[i] = s[i];
    }
}

/**
 * Move the contents of some memory from src to dest without preserving the source
 *
 * Params:
 *  dest = destination memory address
 *  src = source memory address
 *  size = size in bytes to copy
 *
 * Returns: a pointer to the destination memory location
 */
extern(C) void* memmove(void* dest, void* src, size_t size)
{
    memcpy(dest, src, size);

    return dest;
}

extern(C) int memcmp(void* p1, void* p2, size_t size)
{
    ubyte* a = cast(ubyte*)p1;
    ubyte* b = cast(ubyte*)p2;

    for(ulong i=0; i<size; i++)
    {
        if(a[i] > b[i])
            return 1;
        else if(b[i] > a[i])
            return -1;
    }
    
    return 0;
}
