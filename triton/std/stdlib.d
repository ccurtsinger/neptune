/**
 * Externs to standard functions that must be defined by the kernel/host
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module std.stdlib;

extern(C)
{
    void* ptov(ulong pAddr);
}
