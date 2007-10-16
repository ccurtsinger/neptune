module mem.heap;

import dev.screen;
import mem.paging;

import boot.kernel : L4;

struct Heap
{
    void* framePtr = null;
    void* allocPtr = null;
    ulong size = 0;

    void init()
    {
        framePtr = null;
        allocPtr = null;
        size = 0;
    }

    private void* morecore()
    {
        if(framePtr is null)
        {
            L4.map(0x10000000);

            return cast(void*)0x10000000;
        }
        else
        {
            L4.map(cast(ulong)framePtr + mem.paging.FRAME_SIZE);

            return cast(void*)(framePtr + mem.paging.FRAME_SIZE);
        }
    }

    void* allocate(ulong s)
    {
        if(size < s || framePtr is null)
        {
            framePtr = morecore();
            size = mem.paging.FRAME_SIZE;
            allocPtr = framePtr;
        }

        void* p = allocPtr;
        allocPtr += s;
        size -= s;

        return p;
    }

    void free(void* p)
    {
        // Do nothing at all
    }
}
