/**
 * Virtual page frame allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.virtual;

import util.arch.paging;

struct VirtualAllocator
{
    private Range range;
    private size_t ptr;
    
    private bool ascending;
    
    public static VirtualAllocator opCall(Range range, bool ascending = true)
    {
        VirtualAllocator v;
        
        v.range = range;
        v.ascending = ascending;
        
        if(ascending)
            v.ptr = range.base;
        else
            v.ptr = range.top;
        
        return v;
    }
    
    public size_t base()
    {
        if(ascending)
            return range.base;
        else
            return ptr;
    }
    
    public size_t limit()
    {
        if(ascending)
            return ptr;
        else
            return range.top;
    }
    
    public Range allocate(size_t size = FRAME_SIZE)
    {
        size_t ret;
        if(ascending)
        {
            ret = ptr;
            ptr += size;
        }
        else
        {
            ptr -= size;
            ret = ptr;
        }
        
        assert(ret >= range.base && ret <= range.top - FRAME_SIZE, "Out of virtual memory");
        
        return Range(ret, ret + size);
    }
}
