/**
 * Language support for failed asserts and errors
 *
 * Authors: Charlie Curtsinger
 * Date: March 11th, 2008
 * Version: 0.4
 */
 
module error;

/**
 * Failed assert
 *
 * Params:
 *  file = file path where assert failed
 *  line = line number where assert failed
 */
extern (C) void _d_assert(char[] file, uint line)
{
	_d_error("assert failed", file, line);
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
    _d_error(msg, file, line);
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
	_d_error("switch error", file, line);
}
