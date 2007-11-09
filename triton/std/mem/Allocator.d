
module std.mem.Allocator;

class Allocator
{
    abstract void add(void* base, size_t limit);
    
    abstract void* allocate(size_t size);
    
    abstract void free(void* p);
    
    abstract size_t getFreeSize();
    
    abstract size_t getAllocatedSize();
    
    abstract size_t getOverheadSize();
}
