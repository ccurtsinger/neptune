/**
 * Watermark heap allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.kernel;

import util.arch.arch;
import util.arch.paging;

struct WatermarkAllocator
{
    ulong start;
    private PageTable* pagetable;
    private void* watermark;
    private void* limit;
 
    public void init(PageTable* pagetable, ulong watermark)
    {
        start = watermark;
        
        this.pagetable = pagetable;
        this.watermark = cast(void*)watermark;
        this.limit = this.watermark;
    }
    
    public ulong end()
    {
        return cast(ulong)limit;
    }
    
    public void* allocate(size_t size)
    {
        // Word-align all allocations
        size_t offset = size % size_t.sizeof;
        size += size_t.sizeof - offset;
        
        while(limit - watermark < size)
        {
            Page* p = (*pagetable)[cast(ulong)limit];
            p.address = p_alloc();
            p.writable = true;
            p.present = true;
            p.user = true;
            
            limit += FRAME_SIZE;
        }

        void* p = watermark;
        watermark += size;
        return p;
    }
    
    public void free(void* p)
    {
        
    }
}
