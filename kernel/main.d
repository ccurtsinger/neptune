module kernel.main;

import kernel.arch.native;

import std.port;
import std.mem;

extern(C) void _main()
{
    startup();
    
    println("Hello World!");
    
    asm
    {
        "int $13";
    }
    
    for(;;){}
}

extern(C) void abort()
{
    assert(false, "abort");
}

extern (C) void _d_array_bounds(char[] file, uint line)
{
    _d_assert_msg("array bounds exceeded", file, line);
}

extern(C) void _d_assert_msg(char[] msg, char[] file, uint line)
{
    println(msg);
    print("   ");
    println(file);
    
    for(;;){}
}

extern(C) void _d_assert(char[] file, uint line)
{
    _d_assert_msg("assert failed", file, line);
}
