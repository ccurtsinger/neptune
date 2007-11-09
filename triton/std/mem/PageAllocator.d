
module std.mem.PageAllocator;

class PageAllocator
{
    abstract void add(size_t base, size_t size);
    
    abstract ulong getPage();
    
    abstract void freePage(ulong base);
    
    abstract size_t getFreeSize();
    
    abstract size_t getAllocatedSize();
    
    abstract size_t getOverheadSize();
}
