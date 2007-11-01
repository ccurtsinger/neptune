/**
 * Externs to standard functions that must be defined by the kernel/host
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
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
    
    void putc(char c);
    char getc();
    
    void* malloc(size_t s);
    void  free(void* p);
}
