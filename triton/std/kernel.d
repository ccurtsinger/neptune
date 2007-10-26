module std.kernel;

const ulong FRAME_SIZE = 0x1000;

extern(C)
{
    ulong get_physical_page();
    bool is_canonical(void* vAddr);
    void* ptov(ulong pAddr);
    ulong vtop(void* vAddr);
    bool map(ulong vAddr);
}
