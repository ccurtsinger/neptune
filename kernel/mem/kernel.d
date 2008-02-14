module kernel.mem.kernel;

import arch.x86_64.arch;
import arch.x86_64.paging;

struct KernelMemory
{
    PageTable* pagetable;
    void* watermark; 
 
    public void init(PageTable* pagetable)
    {
        this.pagetable = pagetable;
        this.watermark = cast(void*)0x100000;
    }
    
    public void* get(size_t size)
    { 
        if(cast(ulong)watermark % FRAME_SIZE == 0)
        {
            Page* p = (*pagetable)[cast(ulong)watermark];
            p.address = _d_palloc();
            p.writable = true;
            p.present = true;
        }

        void* p = watermark;
        watermark += size;
        return p;
    }
}

