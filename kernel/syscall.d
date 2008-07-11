/**
 * System calls
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.syscall;

import std.stdio;
import std.string;

struct Test
{
    int a;
    int b;
    int c;
}

extern(C) void syscall_a(char* str1, Test t)
{
    write(ctodstr(str1));
    writefln("[%u, %u, %u]", t.a, t.b, t.c);
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
