/**
 * Externs to standard functions that must be defined by the kernel/host
 *
 * Authors: Charlie Curtsinger
 * Date: October 29th, 2007
 * Version: 0.1a
 */

module std.stdlib;

const ulong FRAME_SIZE = 0x1000;

extern(C)
{
    ulong get_physical_page();
    bool is_canonical(void* vAddr);
    void* ptov(ulong pAddr);
    ulong vtop(void* vAddr);
    bool map(ulong vAddr);
}
