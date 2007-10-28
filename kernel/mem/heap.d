module kernel.mem.heap;

import std.kernel;

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
            map(0x10000000);

            return cast(void*)0x10000000;
        }
        else
        {
            map(cast(ulong)framePtr + FRAME_SIZE);

            return cast(void*)(framePtr + FRAME_SIZE);
        }
    }

    void* allocate(ulong s)
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

    void free(void* p)
    {
        // Do nothing at all
    }
}
