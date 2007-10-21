module mem.allocator;

import std.stdio;

const ulong LINEAR_MEM_BASE = 0xFFFF830000000000;
const ulong FRAME_SIZE = 0x1000;

struct Block
{
    ulong base;
    ulong size;
    Block* next;
}

class FixedAllocator
{
    Block* pool;
    Block* free;

    this()
    {
        pool = null;
        free = null;
    }

    new(size_t size, void* pos)
    {
        return pos;
    }

    void addRange(ulong base, ulong size)
    {
        // Calculate the offset from the start of a page
        ulong offset = base%FRAME_SIZE;

        if(offset > 0)
        {
            base += FRAME_SIZE-offset;
        }

        offset = size%FRAME_SIZE;

        if(offset > 0)
        {
            size -= offset;
        }

        if(poolEmpty())
        {
            Block* b = cast(Block*)(LINEAR_MEM_BASE + base);
            b.base = base+Block.sizeof;
            b.size = size-Block.sizeof;
            b.next = pool;

            pool = b;
        }

        if(size >= FRAME_SIZE)
        {
            Block* b = poolAllocate();

            b.base = base;
            b.size = size;
            b.next = free;

            free = b;
        }
    }

    bool poolEmpty()
    {
        if(pool is null)
        {
            return true;
        }
        else if(pool.size < Block.sizeof && pool.next is null)
        {
            return true;
        }

        return false;
    }

    Block* poolAllocate()
    {
        while(pool !is null)
        {
            if(pool.size >= Block.sizeof)
            {
                Block* ret = cast(Block*)(LINEAR_MEM_BASE + pool.base);
                pool.base += Block.sizeof;
                pool.size -= Block.sizeof;

                return ret;
            }

            pool = pool.next;
        }

        write("Memory meta-pool empty\n");
        for(;;){}

        return null;
    }

    ulong fetch()
    {
        while(free !is null)
        {
            if(free.size >= FRAME_SIZE)
            {
                ulong ret = free.base;
                free.base += FRAME_SIZE;
                free.size -= FRAME_SIZE;

                return ret;
            }

            free = free.next;
        }

        write("Out of memory\n");
        for(;;){}

        return 0;
    }

    void release(ulong addr)
    {
        addRange(addr, FRAME_SIZE);
    }
}
