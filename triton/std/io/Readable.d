/**
 * Base interface for readable objects
 *
 * Authors: Charlie Curtsinger
 * Date: November 4th, 2007
 * Version: 0.2a
 */

module std.io.Readable;

import std.io.Writable;

interface Readable
{
	abstract char getc();
	
	char[] read(size_t length, Writable output = null);
	
	char[] readln(Writable output = null, char delimiter = '\n');
}
