
module kernel.mem.dummy;

import std.mem.Allocator;

class DummyAllocator : Allocator
{
    private void* base;
    private size_t limit;
    private size_t allocated;
    
    new(size_t size, void* p)
    {
        return p;
    }
    
    public void add(void* base, size_t limit)
    {
        this.base = base;
        this.limit = limit;
        this.allocated = 0;
    }
    
    public void* allocate(size_t size)
    {
        void* p = base;
        
        base += size;
        limit -= size;
        
        return p;
    }
    
    public void free(void* p)
    {
        // Do nothing
    }
    
    public size_t getAllocatedSize(void* p)
    {
        return 0;
    }
    
    public size_t getFreeSize()
    {
        return limit;
    }
    
    public size_t getAllocatedSize()
    {
        return allocated;
    }
    
    public size_t getOverheadSize()
    {
        return 0;
    }
}
