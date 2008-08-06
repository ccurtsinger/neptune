/**
 * Watermark heap allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.heap;

import kernel.core.env;

import util.arch.paging;

ulong start;
PageTable* pagetable;
void* watermark;
void* limit;

extern(C) void m_init(PageTable* init_pagetable)
{
    start = KERNEL_HEAP.base;
    
    pagetable = init_pagetable;
    watermark = cast(void*)KERNEL_HEAP.base;
    limit = watermark;
}

extern(C) void* m_alloc(size_t size)
{
    // Word-align all allocations
    size_t offset = size % size_t.sizeof;
    size += size_t.sizeof - offset;
    
    while(limit - watermark < size)
    {
        assert(cast(size_t)limit < KERNEL_HEAP.top, "Kernel heap overlow");
        
        Page* p = (*pagetable)[cast(ulong)limit];
        p.address = p_alloc();
        p.writable = true;
        p.present = true;
        p.user = false;
        
        limit += FRAME_SIZE;
    }

    void* p = watermark;
    watermark += size;
    return p;
}

extern(C) void m_free(void* p)
{
    
}

extern(C) size_t m_size(void* p)
{
    return 0;
}

extern(C) size_t m_base()
{
    return start;
}

extern(C) size_t m_limit()
{
    return cast(size_t)limit;
}
