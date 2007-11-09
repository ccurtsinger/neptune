
module kernel.mem.dummy;

import std.mem.Allocator;

class DummyAllocator : Allocator
{
    private void* base;
    private size_t limit;
    
    new(size_t size, void* p)
    {
        return p;
    }
    
    public void add(void* base, size_t limit)
    {
        this.base = base;
        this.limit = limit;
    }
    
    public void* allocate(size_t size)
    {
        void* p = base;
        
        base += size;
        
        return p;
    }
    
    public void free(void* p)
    {
        // Do nothing
    }
}
