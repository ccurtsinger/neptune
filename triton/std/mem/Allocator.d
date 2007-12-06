
module std.mem.Allocator;

class Allocator
{
    public abstract void add(void* base, size_t limit);
    
    public abstract void* allocate(size_t size);
    
    public abstract void free(void* p);
    
    public abstract size_t getFreeSize();
    
    public abstract size_t getAllocatedSize();
    
    public abstract size_t getAllocatedSize(void* p);
    
    public abstract size_t getOverheadSize();
}
