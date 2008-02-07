/**
 * Language support for failed asserts and errors
 *
 * Authors: Walter Bright, Sean Kelly, Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */
 
module error;
 
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
	System.output.newline.write(msg);
	
	if(file !is null && line > 0)
	{
	    System.output.writef(" (%s, line %u)", file, line);
	}
	
	System.output.newline;
		
	for(;;){}
}

version(x86_64)
{
    void stackUnwind(size_t depth = 6)
    {
        ulong* rsp;
        ulong* rbp;
        
        asm
        {
            "mov %%rsp, %[stack]" : [stack] "=a" rsp;
            "mov %%rbp, %[frame]" : [frame] "=a" rbp;
        }
        
        for(size_t i=0; i<depth; i++)
        {
            rsp = rbp;
            rbp = cast(ulong*)rsp[0];
            System.output.writef("unwind %016#X", rsp[1]).newline;
        }
    }
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
