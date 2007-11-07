

module std.io.CharStream;

import std.io.Stream;
import std.stdarg;
import std.collection.stack;

class CharInputStream /*: InputStream!(char)*/
{
	public abstract char read();
	
	public char[] read(size_t size, char[] buf = null)
	{
		char[] ret;
		
		if(buf !is null)
			ret = buf;
		else
			ret = new char[size];
		
		for(size_t i=0; i<size; i++)
		{
			ret[i] = read();
		}
		
		return ret;
	}
	
	char[] readln(CharOutputStream output = null, char delimiter = '\n')
	{
		auto buf = new FastStack!(char);
			
		char c;
		
		do
		{
			c = read();
			
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

class CharOutputStream /*: OutputStream!(char)*/
{
	public abstract CharOutputStream write(char c);
	
	public CharOutputStream write(char[] str)
	{
		foreach(char c; str)
		{
			write(c);
		}
		
		return this;
	}

	public CharOutputStream writef(...)
	{
		foreach(TypeInfo t; _arguments)
		{
			if(t.classinfo is typeid(Object).classinfo)
			{
				Object a = va_arg!(Object)(_argptr);
				//write(a);
			}
			else if(t is typeid(char))
			{
				char a = va_arg!(char)(_argptr);
				write(a);
			}
			else if(t is typeid(ulong))
			{
				ulong a = va_arg!(ulong)(_argptr);
				//write(a);
			}
			else if(t is typeid(uint))
			{
				uint a = va_arg!(uint)(_argptr);
				//write(a);
			}
			else if(t is typeid(ushort))
			{
				ushort a = va_arg!(ushort)(_argptr);
				//write(a);
			}
			else if(t is typeid(ubyte))
			{
				ubyte a = va_arg!(ubyte)(_argptr);
				
				//write(a);
			}
			else if(t is typeid(long))
			{
				long a = va_arg!(long)(_argptr);
				
				//write(a);
			}
			else if(t is typeid(int))
			{
				int a = va_arg!(int)(_argptr);
				
				//write(a);
			}
			else if(t is typeid(short))
			{
				short a = va_arg!(short)(_argptr);
				
				//write(a);
			}
			else if(t is typeid(byte))
			{
				byte a = va_arg!(byte)(_argptr);
				
				//write(a);
			}
			else if(t.classinfo is typeid(Object[]).classinfo)
			{
				Object[] a = va_arg!(Object[])(_argptr);
				
				//write(a);
			}
			else if(t == typeid(char[]))
			{
				char[] a = va_arg!(char[])(_argptr);
				write(a);
			}
			else if(t.classinfo.name == "TypeInfo_Pointer")
			{
				void* a = va_arg!(void*)(_argptr);
				//write(a);
			}
			else
			{
				write(t.classinfo.name);
			}
		}
		
		return this;
	}
	
	CharOutputStream newline()
	{
		write('\n');
		
		return this;
	}
}
