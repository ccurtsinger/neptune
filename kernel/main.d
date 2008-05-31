/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.arch.native;

import std.port;
import std.mem;
import std.stdio;

extern(C) void _main()
{
    startup();
    
    asm
    {
        "int $0" : : "a" 0x12345;
    }
    
    for(;;){}
}
