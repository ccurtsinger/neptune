/**
 * Language support for failed asserts and errors
 *
 * Authors: Walter Bright, Sean Kelly, Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2004-2008 Digital Mars, www.digitalmars.com
 */
 
/*
 *  Copyright (C) 2004-2008 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
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
