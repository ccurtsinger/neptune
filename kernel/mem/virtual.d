/**
 * Virtual memory allocation
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module kernel.mem.virtual;

import neptune.arch.paging;

import std.stdlib;

/**
 * Temporary heap allocation with built-in page allocation
 * 
 * Currently performs no freeing of memory, and stores no meta-data
 * in allocated blocks.
 */
struct Heap
{
    VirtualMemory* mem;
    void* framePtr = null;
    void* allocPtr = null;
    ulong size = 0;

    /**
     * Initialize the heap
     */
    void init(VirtualMemory* mem)
    {
        this.mem = mem;
        framePtr = null;
        allocPtr = null;
        size = 0;
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
            mem.map(framePtr + FRAME_SIZE);

            return cast(void*)(framePtr + FRAME_SIZE);
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
    void* allocate(size_t s)
    {
        if(size < s || framePtr is null)
        {
            framePtr = morecore();
            size = FRAME_SIZE;
            allocPtr = framePtr;
        }

        void* p = allocPtr;
        allocPtr += s;
        size -= s;

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
        // Do nothing at all
    }
}
