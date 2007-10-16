module mem.util;

extern(C) void memset(void* p, ubyte value, ulong size)
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

extern(C) void memsets(void* p, ushort value, ulong size)
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

extern(C) void memcpy(void* dest, void* src, ulong size)
{
    ubyte* d = cast(ubyte*)dest;
    ubyte* s = cast(ubyte*)src;

    // If copying forwards is safe
    if(dest < src)
    {
        for(ulong i=0; i<size; i++)
        {
            d[i] = s[i];
        }
    }
    else
    {
        // memcpy backwards
        for(ulong i=size-1; i>=0; i--)
        {
            d[i] = s[i];
        }
    }
}

extern(C) void* memmove(void* dest, void* src, ulong size)
{
    memcpy(dest, src, size);

    return dest;
}

extern(C) int memcmp(void* p1, void* p2, size_t size)
{
    int sum = 0;

    uint* i1 = cast(uint*)p1;
    uint* i2 = cast(uint*)p2;

    for(int i=0; i<size/uint.sizeof; i++)
    {
        sum += i1[i];
        sum -= i2[i];
    }
    return sum;
}
