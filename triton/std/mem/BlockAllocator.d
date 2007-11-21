
module std.mem.BlockAllocator;

class BlockAllocator
{
    public abstract void add(void* base, size_t limit);
    
    public abstract void* allocate();
    
    public abstract void free(void* p);
    
    public abstract size_t getBlockSize();
    
    public abstract size_t getFreeSize();
    
    public abstract size_t getAllocatedSize();
    
    public abstract size_t getOverheadSize();
}
