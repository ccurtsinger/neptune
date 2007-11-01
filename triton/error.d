/**
 * Language support for failed asserts and errors
 *
 * Authors: Walter Bright, Sean Kelly, Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */
 
module error;
 
import std.stdio;
import std.integer;

/**
 * Display an error message and halt
 *
 * Params:
 *  msg = message to display
 *  file = file path where error occurred
 *  line = line number where error occurred
 */
void onError(char[] msg, char[] file = null, ulong line = 0)
{
	write("\n  ");
	write(msg);
	
	if(file !is null && line > 0)
	{
		write(" (");
		write(file);
		write(", line ");
		write(line);
		write(")");
	}
	
	write("\n");
		
	for(;;){}
}

/**
 * Failed assert
 *
 * Params:
 *  file = file path where assert failed
 *  line = line number where assert failed
 */
extern (C) void _d_assert(char[] file, uint line)
{
	onError("assert failed", file, line);
}

/**
 * Failed assert with error message
 *
 * Params:
 *  msg = message to display
 *  file = file path where assert failed
 *  line = line number where assert failed
 */
extern (C) static void _d_assert_msg(char[] msg, char[] file, uint line)
{
    onError(msg, file, line);
}

/**
 * Switch error
 *
 * Params:
 *  file = file path where switch error occurred
 *  line = line number where switch error occurred
 */
extern (C) void _d_switch_error(char[] file, uint line)
{
	onError("switch error", file, line);
}
