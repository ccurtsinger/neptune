/**
 * Virtual memory allocation
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module kernel.mem.virtual;

import neptune.arch.paging;

import std.mem.Allocator;

import std.stdlib;

/**
 * Temporary heap allocation with built-in page allocation
 * 
 * Currently performs no freeing of memory, and stores no meta-data
 * in allocated blocks.
 */
class Heap : Allocator
{
    VirtualMemory* mem;
    void* framePtr = null;
    void* allocPtr = null;
    size_t freeSize = 0;
    size_t allocatedSize = 0;

    /**
     * Initialize the heap
     */
    this(VirtualMemory* mem)
    {
        this.mem = mem;
        framePtr = null;
        allocPtr = null;
        freeSize = 0;
        allocatedSize = 0;
    }
    
    void add(void* base, size_t size)
    {
        // do nothing for now
    }

    /**
     * Temporary morecore implementation
     * 
     * Returns: a pointer to the next free virtual page in the heap
     */
    private void* morecore()
    {
        if(framePtr is null)
        {
            mem.map(cast(void*)0x10000000);

            return cast(void*)0x10000000;
        }
        else
        {
            mem.map(framePtr + System.pageSize);

            return cast(void*)(framePtr + System.pageSize);
        }
    }

    /**
     * Allocate a piece of memory
     *
     * Params:
     *  s = size of the memory to allocate
     *
     * Returns: Pointer to the allocated memory
     */
    void* allocate(size_t size)
    {
        if(freeSize < size || framePtr is null)
        {
            framePtr = morecore();
            freeSize = System.pageSize;
            allocPtr = framePtr;
        }

        void* p = allocPtr;
        allocPtr += size;
        freeSize -= size;

        return p;
    }

    /**
     * Free allocated memory (stub)
     *
     * Params:
     *  p = pointer to the memory to be freed
     */
    void free(void* p)
    {
        // Do nothing
    }
    
    public size_t getFreeSize()
    {
        return freeSize;
    }
    
    public size_t getAllocatedSize()
    {
        return allocatedSize;
    }
    
    public size_t getOverheadSize()
    {
        return 0;
    }
}
