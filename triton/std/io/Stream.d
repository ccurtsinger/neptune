/**
 * Input and output streams
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module std.io.Stream;

import std.stdarg;
import std.collection.stack;

interface Readable
{
	char getc();
	
	char[] read(size_t length, void delegate(char c) putc = null);
	
	char[] readln(void delegate(char c) putc = null);
}

interface Writable
{
	void putc(char c);
	
	void write(char[] str);
	
	void writeln(char[] str);
	
	void writef(...);
	
	void writefln(...);
}

class InputStream : Readable
{
	abstract char getc();
	
	char[] read(size_t length, void delegate(char c) putc = null)
	{
		return std.io.Stream.read(&getc, length, putc);
	}
	
	char[] readln(void delegate(char c) putc = null)
	{
		return std.io.Stream.readln(&getc, putc);
	}
}

class OutputStream : Writable
{
	abstract void putc(char c);
	
	void write(char[] str)
	{
		std.io.Stream.write(&putc, str);
	}
	
	void writeln(char[] str)
	{
		write(str);
		putc('\n');
	}
	
	void writef(...)
	{
		std.io.Stream.writef(&putc, _arguments, _argptr);
	}
	
	void writefln(...)
	{
		std.io.Stream.writef(&putc, _arguments, _argptr);
		putc('\n');
	}
}

private
{
	void write(void delegate(char c) putc, char[] str)
	{
		foreach(char c; str)
		{
			putc(c);
		}
	}
	
	void writef(void delegate(char c) putc, TypeInfo[] args, va_list argptr)
	{
		foreach(TypeInfo t; args)
		{
			write(putc, t.toString());
		}
	}
	
	char[] read(char delegate() getc, size_t length, void delegate(char c) putc = null)
	{
		char[] str = new char[length];
		
		for(size_t i=0; i<length; i++)
		{
			str[i] = getc();
			
			if(putc !is null)
			{
				putc(str[i]);
			}
		}
		
		return str;
	}
	
	char[] readln(char delegate() getc, void delegate(char c) putc = null, char delimiter = '\n')
	{
		auto buf = new FastStack!(char);
			
		char c;
		
		do
		{
			c = getc();
			
			if(putc !is null)
			{
				putc(c);
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
