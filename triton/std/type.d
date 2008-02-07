module std.type;

version(x86_64)
{
    alias ulong paddr_t;
    alias void* vaddr_t;
    alias ulong size_t;
    alias long  ptrdiff_t;
    alias size_t hash_t;
}
else version(i586)
{
    alias uint paddr_t;
    alias void* vaddr_t;
    alias uint size_t;
    alias int  ptrdiff_t;
    alias size_t hash_t;
}
else
{
    static assert(false, "Unsupported version");
}
