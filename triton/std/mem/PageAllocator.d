
module std.mem.PageAllocator;

class PageAllocator
{
    public abstract void add(size_t base, size_t size);
    
    public abstract ulong getPage();
    
    public abstract void freePage(ulong base);
    
    public abstract size_t getFreeSize();
    
    public abstract size_t getAllocatedSize();
    
    public abstract size_t getOverheadSize();
}
