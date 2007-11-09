
module std.mem.BlockAllocator;

class BlockAllocator
{
    abstract void add(void* base, size_t limit);
    
    abstract void* allocate();
    
    abstract void free(void* p);
    
    abstract size_t getBlockSize();
    
    abstract size_t getFreeSize();
    
    abstract size_t getAllocatedSize();
    
    abstract size_t getOverheadSize();
}
