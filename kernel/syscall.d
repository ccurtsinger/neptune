/**
 * System calls
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.syscall;

import std.stdio;
import std.string;

extern(C) void syscall_a(char* str1, char* str2)
{
    write(ctodstr(str1));
    write(ctodstr(str2));
    for(size_t i=0; i<3000000; i++){}
}

extern(C) void syscall_b()
{
    write('b');
    for(size_t i=0; i<3000000; i++){}
}

extern(C) void syscall_c()
{
    write('c');
    for(size_t i=0; i<3000000; i++){}
}
