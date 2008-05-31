module error;

import std.stdio;

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
    writefln("%s\n    %s (%u)", msg, file, line);
    
    for(;;){}
}

extern(C) void _d_assert(char[] file, uint line)
{
    _d_assert_msg("assert failed", file, line);
}

extern (C) void _d_switch_error(char[] file, uint line)
{
    _d_assert_msg("switch error", file, line);
}
