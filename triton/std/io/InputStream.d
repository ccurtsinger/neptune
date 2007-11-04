/**
 * Base abstract class for InputStream objects
 *
 * Authors: Charlie Curtsinger
 * Date: November 4th, 2007
 * Version: 0.2a
 */

module std.io.InputStream;

import std.io.Readable;
import std.io.Writable;
import std.collection.stack;

class InputStream : Readable
{
	abstract char getc();
	
	char[] read(size_t length, Writable output = null)
	{
		char[] str = new char[length];
		
		for(size_t i=0; i<length; i++)
		{
			str[i] = getc();
			
			if(output !is null)
			{
				output.write(str[i]);
			}
		}
		
		return str;
	}
	
	char[] readln(Writable output = null, char delimiter = '\n')
	{
		auto buf = new FastStack!(char);
			
		char c;
		
		do
		{
			c = getc();
			
			if(output !is null)
			{
				output.write(c);
			}
			
			buf.push(c);
		
		} while(c != delimiter);
		
		char[] line = new char[buf.size()];
		
		for(size_t i=buf.size(); i>0; i--)
		{
			line[i-1] = buf.pop();
		}
		
		delete buf;
		
		return line;
	}
}
