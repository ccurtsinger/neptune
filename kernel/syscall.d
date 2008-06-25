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
}

extern(C) void syscall_b()
{
    write('b');
}

extern(C) void syscall_c()
{
    write('c');
}
