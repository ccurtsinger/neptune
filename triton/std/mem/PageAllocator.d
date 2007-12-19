
module std.mem.PageAllocator;

class PageAllocator
{
    public abstract void add(paddr_t base, size_t size);
    
    public abstract paddr_t getPage();
    
    public abstract void freePage(paddr_t base);
    
    public abstract size_t getFreeSize();
    
    public abstract size_t getAllocatedSize();
    
    public abstract size_t getOverheadSize();
}
