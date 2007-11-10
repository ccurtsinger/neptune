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
    size_t freedSize = 0;
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
        freedSize = 0;
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
        if(freeSize < size + size_t.sizeof || framePtr is null)
        {
        	allocatedSize += freeSize;
            framePtr = morecore();
            freeSize = System.pageSize;
            allocPtr = framePtr;
        }

		size_t* s = cast(size_t*)allocPtr;
		*s = size;
		
		allocPtr += size_t.sizeof;
		freeSize -= size_t.sizeof;
		allocatedSize += size_t.sizeof;
		
		void* p = allocPtr;
        
        allocPtr += size;
        freeSize -= size;
        allocatedSize += size;

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
    	p -= size_t.sizeof;
        size_t* s = cast(size_t*)p;
        
        if(*s > allocatedSize - size_t.sizeof)
        {
        	System.output.writef("trying to free: %016#x size %016#X", cast(ulong)(p + size_t.sizeof), *s);
			assert(false);
        }
        
        freedSize += *s;
        allocatedSize -= *s;
        
        freedSize += size_t.sizeof;
        allocatedSize -= size_t.sizeof;
        
        // Do nothing
    }
    
    public size_t getFreeSize()
    {
        return freeSize + freedSize;
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
