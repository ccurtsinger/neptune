/**
 * Virtual page frame allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.virtual;

import util.arch.arch;

struct VirtualAllocator
{
    private size_t bottom;
    private size_t ptr;
    private size_t top;
    
    private bool ascending;
    
    public static VirtualAllocator opCall(size_t bottom, size_t top, bool ascending = true)
    {
        VirtualAllocator v;
        
        v.bottom = bottom;
        v.top = top;
        v.ascending = ascending;
        
        if(ascending)
            v.ptr = bottom;
        else
            v.ptr = top;
        
        return v;
    }
    
    public size_t base()
    {
        if(ascending)
            return bottom;
        else
            return ptr;
    }
    
    public size_t limit()
    {
        if(ascending)
            return ptr;
        else
            return top;
    }
    
    public size_t allocate(size_t size = FRAME_SIZE)
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
        
        assert(ret >= bottom && ret <= top - FRAME_SIZE, "Out of virtual memory");
        
        return ret;
    }
}
