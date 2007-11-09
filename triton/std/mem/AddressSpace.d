/**
 * Abstraction for a virtual memory address space
 *
 * Authors: Charlie Curtsinger
 * Date: November 7th, 2007
 * Version: 0.2a
 */

module std.mem.AddressSpace;

import std.mem.Allocator;
import std.mem.PageAllocator;
import std.mem.BlockAllocator;

class AddressSpace
{
    private PageAllocator pmem;
    private BlockAllocator smem;
    private Allocator mem;
    
    new(size_t size)
    {
        return System.memory.heap.allocate(size);
    }
    
    new(size_t size, void* p)
    {
        return p;
    }
    
    public void setPhysicalAllocator(PageAllocator pmem)
    {
        this.pmem = pmem;
    }
    
    public void setStackAllocator(BlockAllocator smem)
    {
        this.smem = smem;
    }
    
    public void setAllocator(Allocator mem)
    {
        this.mem = mem;
    }
    
    public PageAllocator physical()
    {
        return pmem;
    }
    
    public BlockAllocator stack()
    {
        return smem;
    }
    
    public Allocator heap()
    {
        return mem;
    }
}
