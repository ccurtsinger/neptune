/**
 * Virtual memory allocation
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module kernel.mem.HeapAllocator;

//import neptune.arch.paging;
import kernel.arch.Arch;
import kernel.arch.PageTable;

import std.mem.Allocator;

/**
 * Temporary heap allocation with built-in page allocation
 * 
 * Currently performs no freeing of memory, and stores no meta-data
 * in allocated blocks.
 */
class HeapAllocator : Allocator
{
    PageTable* mem;
    void* framePtr = null;
    void* allocPtr = null;
    size_t freeSize = 0;
    size_t freedSize = 0;
    size_t allocatedSize = 0;
    size_t overheadSize = 0;

    /**
     * Initialize the heap
     */
    this(PageTable* mem)
    {
        this.mem = mem;
        framePtr = null;
        allocPtr = null;
        freeSize = 0;
        freedSize = 0;
        allocatedSize = 0;
        overheadSize = 0;
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
            Page* p = (*mem)[0x10000000];
            p.address = System.memory.physical.getPage();
            p.writable = true;
            p.present = true;
            p.superuser = true;
            p.invalidate;
            
			allocPtr = cast(void*)0x10000000;
            
            return cast(void*)0x10000000;
        }
        else
        {
            Page* p = (*mem)[framePtr + FRAME_SIZE];
            p.address = System.memory.physical.getPage();
            p.writable = true;
            p.present = true;
            p.superuser = true;
            p.invalidate();

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
    void* allocate(size_t size)
    {
        if(freeSize < size + size_t.sizeof || framePtr is null)
        {
        	//allocatedSize += freeSize;
            framePtr = morecore();
            freeSize += FRAME_SIZE;
            //allocPtr = framePtr;
        }

		size_t* s = cast(size_t*)allocPtr;
		*s = size;
		
		allocPtr += size_t.sizeof;
		freeSize -= size_t.sizeof;
		overheadSize += size_t.sizeof;
		
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
        
        if(allocatedSize < *s || overheadSize < size_t.sizeof)
        {
        	System.output.writef("trying to free: %016#x size %016#X", cast(ulong)(p + size_t.sizeof), *s);
			assert(false);
        }
        
        freedSize += *s;
        allocatedSize -= *s;
        
        freedSize += size_t.sizeof;
        overheadSize -= size_t.sizeof;
        
        // Do nothing
    }
    
    /**
     * Get the size of a specific allocated region
     */
    public size_t getAllocatedSize(void* p)
    {
        p -= size_t.sizeof;
        return *cast(size_t*)p;
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
        return overheadSize;
    }
}
