module neptune.mem.allocate.physical;

import std.kernel;

struct MemBlock
{
    ulong base;
    ulong size;
    MemBlock* next;
}

struct PhysicalAllocator
{
    MemBlock* local;
    MemBlock* free;

    size_t sizeLocal;
    size_t sizeFree;
    size_t sizeAllocated;

    void init()
    {
        local = null;
        free = null;

        sizeLocal = 0;
        sizeFree = 0;
        sizeAllocated = 0;
    }

    void add(ulong base, ulong size)
    {
        // Move the base up to the next frame-aligned address
        ulong baseShift = FRAME_SIZE - (base % FRAME_SIZE);

        if(baseShift < FRAME_SIZE)
        {
            base += baseShift;
            size -= baseShift;
        }

        // Adjust the size so it is FRAME_SIZE aligned
        size -= size % FRAME_SIZE;

        // Check to make sure at least one page is being added
        if(size >= FRAME_SIZE)
        {
            if(sizeLocal < 2*MemBlock.sizeof)
            {
                addLocal(base);
                base += FRAME_SIZE;
                size -= FRAME_SIZE;
            }

            MemBlock* newblock = getLocal();

            assert(newblock !is null, "Error - no meta data memory available on insertion");

            newblock.base = base;
            newblock.size = size;
            newblock.next = free;
            free = newblock;

            sizeFree += size;
        }
        else
        {
            assert(false, "Unable to add physical memory in blocks smaller than FRAME_SIZE after alignment");
        }
    }

    /**
     * Allocate a page of physical memory.
     * Returns the physical address of the allocated memory
     */
    ulong allocate()
    {
        if(sizeFree >= FRAME_SIZE && free !is null)
        {
            if(free.size >= FRAME_SIZE)
            {
                ulong pAddr = free.base;
                free.base += FRAME_SIZE;
                free.size -= FRAME_SIZE;
                sizeFree -= FRAME_SIZE;
                sizeAllocated += FRAME_SIZE;

                return pAddr;
            }
            else
            {
                sizeFree -= free.size;
                free = free.next;

                return allocate();
            }
        }
        else
        {
            assert(false, "Unable to allocate physical page - out of memory");
        }
    }

    void release(ulong base, ulong size = FRAME_SIZE)
    {
        add(base, size);
        sizeAllocated -= size;
    }

    /**
     * Add memory to the local pool for meta data
     */
    void addLocal(ulong base, ulong size = FRAME_SIZE)
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

        sizeLocal += size;
    }

    /**
     * Get a MemBlock pointer from the local meta data pool.
     * Return null if no memory is available
     */
    MemBlock* getLocal()
    {
        if(local != null)
        {
            if(local.size >= MemBlock.sizeof)
            {
                MemBlock* p = cast(MemBlock*)ptov(local.base);
                local.base += MemBlock.sizeof;
                local.size -= MemBlock.sizeof;

                sizeLocal -= MemBlock.sizeof;

                return p;
            }
            else
            {
                sizeLocal -= local.size;
                local = local.next;
                return getLocal();
            }
        }

        return null;
    }
}
