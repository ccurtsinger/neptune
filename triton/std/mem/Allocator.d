
module std.mem.Allocator;

class Allocator
{
    abstract void add(void* base, size_t limit);
    
    abstract void* allocate(size_t size);
    
    abstract void free(void* p);
}
