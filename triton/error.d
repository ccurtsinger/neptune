
import std.stdio;

extern (C) void _d_assert(char[] file, uint line)
{
    writefln("_d_assert(file: %s, line: %u)", file, line);
    
    for(;;){}
}

extern (C) static void _d_assert_msg(char[] msg, char[] file, uint line)
{
    writefln("_d_assert_msg(file: %s, line: %u)\n  %s", file, line, msg);
    
    for(;;){}
}

extern (C) void _d_array_bounds(char[] file, uint line)
{
    writefln("_d_array_bounds(file: %s, line: %u)", file, line);
    
    for(;;){}
}

extern (C) void _d_switch_error(char[] file, uint line)
{
    writefln("_d_switch_error(file: %s, line: %u)", file, line);
    
    for(;;){}
}
