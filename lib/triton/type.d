/**
 * Type defines for various architectures
 *
 * Copyright: 2008 The Neptune Project
 */

module type;

version(x86_64)
{
    alias ulong size_t;
    alias long  ptrdiff_t;
    alias size_t hash_t;
}
else version(i586)
{
    alias uint size_t;
    alias int  ptrdiff_t;
    alias size_t hash_t;
}
else
{
    static assert(false, "Unsupported version");
}

struct Range
{
    ulong base;
    ulong top;
    
    public static Range opCall(ulong base, ulong top)
    {
        Range r;
        r.base = base;
        r.top = top;
        return r;
    }
    
    public ulong size()
    {
        return top - base;
    }
    
    public void size(ulong s)
    {
        top = base + s;
    }
}
