
module kernel.mem.range;

struct MemoryRange
{
    public size_t base;
    public size_t size;
    
    public static MemoryRange opCall(size_t base, size_t size)
    {
        MemoryRange m;
        
        m.base = base;
        m.size = size;
        
        return m;
    }
    
    public size_t top()
    {
        return base + size;
    }
    
    public void top(size_t t)
    {
        assert(t >= base, "cannot define range with negative size");
        
        size = t - base;
    }
    
    public MemoryRange aligned(size_t alignment)
    {
        MemoryRange r = MemoryRange(base, size);
        
        size_t offset = base % alignment;
        r.base -= alignment;
        r.size += alignment;
        
        offset = r.size % alignment;
        
        if(offset > 0)
            r.size += alignment - offset;
            
        return r;
    }
}
