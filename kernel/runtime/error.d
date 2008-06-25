/**
 * Support for compiler-generated error handling calls
 *
 * Copyright: 2008 The Neptune Project
 */

module error;

import std.stdio;

/**
 * Invoked on failure when building a release configuration
 */
extern(C) void abort()
{
    assert(false, "abort");
}

/**
 * Handle an out-of-bounds array access
 *
 * Params:
 *  file = file name
 *  line = line in file
 */
extern (C) void _d_array_bounds(char[] file, uint line)
{
    _d_assert_msg("array bounds exceeded", file, line);
}

/**
 * Handle a failed assert
 *
 * Params:
 *  msg = assert message
 *  file = file name
 *  line = line in file
 */
extern(C) void _d_assert_msg(char[] msg, char[] file, uint line)
{
    writefln("%s\n    %s (%u)", msg, file, line);
    
    for(;;){}
}

/**
 * Handle a failed assert without a message
 *
 * Params:
 *  file = file name
 *  line = line in file
 */
extern(C) void _d_assert(char[] file, uint line)
{
    _d_assert_msg("assert failed", file, line);
}

/**
 * Handle a failed switch statement
 *
 * Params:
 *  file = file name
 *  line = line in file
 */
extern (C) void _d_switch_error(char[] file, uint line)
{
    _d_assert_msg("switch error", file, line);
}
