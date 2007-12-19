/**
 * Physical memory allocation system
 *
 * Authors: Charlie Curtsinger
 * Date: November 9th, 2007
 * Version: 0.2a
 */

module kernel.mem.PhysicalAllocator;

import std.mem.PageAllocator;

import kernel.arch.Arch;

/**
 * Physical memory allocator that distributes free pages
 *
 * Uses zero-overhead when no memory is present.  Memory is taken
 * as needed to store metadata.
 */
class PhysicalAllocator : PageAllocator
{
    /// Pointer to the list of free meta-pool memory
    private MemBlock* local = null;
    
    /// Pointer to the list of free public memory
    private MemBlock* free = null;

    /// Size of the local free pool
    private size_t localSize = 0;
    
    /// Size of the free public pool
    private size_t freeSize = 0;
    
    /// Amount of public memory allocated
    private size_t allocatedSize = 0;
    
    public this()
    {
        local = null;
        free = null;
        localSize = 0;
        freeSize = 0;
        allocatedSize = 0;
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
        return localSize;
    }

    /**
     * Add a block of memory to the allocator
     *
     * Params:
     *  base = base address of the block
     *  size = size of the block
     */
    public void add(paddr_t base, size_t size)
    {
        // Move the base up to the next frame-aligned address
        ulong baseShift = System.pageSize - (base % System.pageSize);

        if(baseShift < System.pageSize)
        {
            base += baseShift;
            size -= baseShift;
        }

        // Adjust the size so it is FRAME_SIZE aligned
        size -= size % System.pageSize;

        // Check to make sure at least one page is being added
        if(size >= System.pageSize)
        {
            if(localSize < 2*MemBlock.sizeof)
            {
                addLocal(base);
                base += System.pageSize;
                size -= System.pageSize;
            }

            MemBlock* newblock = getLocal();

            assert(newblock !is null, "Error - no meta data memory available on insertion");

            newblock.base = base;
            newblock.size = size;
            newblock.next = free;
            free = newblock;

            freeSize += size;
        }
        else
        {
            assert(false, "Unable to add physical memory in blocks smaller than FRAME_SIZE after alignment");
        }
    }

    /**
     * Allocate a page of physical memory.
     *
     * Returns: the physical address of the allocated memory
     */
    public paddr_t getPage()
    {
        if(freeSize >= System.pageSize && free !is null)
        {
            if(free.size >= System.pageSize)
            {
                paddr_t pAddr = free.base;
                free.base += System.pageSize;
                free.size -= System.pageSize;
                freeSize -= System.pageSize;
                allocatedSize += System.pageSize;

                return pAddr;
            }
            else
            {
                freeSize -= free.size;
                free = free.next;

                return getPage();
            }
        }
        else
        {
            assert(false, "Unable to allocate physical page - out of memory");
        }
    }

    /**
     * Release a block of physical memory
     *
     * Params:
     *  base = base address of the block
     *  size = size of the block
     */
    public void freePage(paddr_t base)
    {
        add(base, System.pageSize);
        allocatedSize -= System.pageSize;
    }

    /**
     * Add memory to the local pool for meta data
     *
     * Params:
     *  base = base address of the block
     *  size = size of the block
     */
    private void addLocal(paddr_t base, size_t size = System.pageSize)
    {
        MemBlock* newblock = getLocal();

        if(newblock is null)
        {
            newblock = cast(MemBlock*)ptov(base);
            base += MemBlock.sizeof;
            size -= MemBlock.sizeof;
        }

        newblock.base = base;
        newblock.size = size;
        newblock.next = local;
        local = newblock;

        localSize += size;
    }

    /**
     * Get a MemBlock pointer from the local meta data pool.
     *
     * ReturnS: null if no memory is available, otherwise the next local memory block
     */
    private MemBlock* getLocal()
    {
        if(local != null)
        {
            if(local.size >= MemBlock.sizeof)
            {
                MemBlock* p = cast(MemBlock*)ptov(local.base);
                local.base += MemBlock.sizeof;
                local.size -= MemBlock.sizeof;

                localSize -= MemBlock.sizeof;

                return p;
            }
            else
            {
                localSize -= local.size;
                local = local.next;
                return getLocal();
            }
        }

        return null;
    }
    
    /**
     * Wrapper struct for memory in the local of public pool
     */
    private struct MemBlock
    {
        paddr_t base;
        size_t size;
        MemBlock* next;
    }
}
