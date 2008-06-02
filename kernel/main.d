/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.arch.native;
import kernel.spec.multiboot;

import std.port;
import std.mem;
import std.stdio;

extern(C) void _main(MultibootInfo* multiboot, uint magic)
{
    startup();
    
    writeln(multiboot.getCommand());
    
    for(;;){}
}
