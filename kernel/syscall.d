/**
 * System calls
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.syscall;

import std.stdio;

extern(C) void syscall_a()
{
    write('a');
    for(size_t i=0; i<1000000; i++){}
}

extern(C) void syscall_b()
{
    write('b');
    for(size_t i=0; i<1000000; i++){}
}

extern(C) void syscall_c()
{
    write('c');
    for(size_t i=0; i<1000000; i++){}
}
