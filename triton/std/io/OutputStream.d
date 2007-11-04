/**
 * Base abstract class for OutputStream objects
 *
 * Authors: Charlie Curtsinger
 * Date: November 4th, 2007
 * Version: 0.2a
 */

module std.io.OutputStream;

import std.io.Writable;
import std.stdarg;

class OutputStream : Writable
{
	abstract void putc(char c);
	
	private void writePad(size_t length, int pad, char padchar)
	{
		for(int i=length; i<pad; i++)
		{
			putc(padchar);
		}
		
		return this;
	}
	
	private size_t digits(ulong i, int radix = 10)
	{
		if(i == 0)
			return 1;

		long d = 0;

		while(i > 0)
		{
			i -= i%radix;
			i /= radix;
			d++;
		}

		return d;
	}
	
	OutputStream write(char arg, int pad = 0)
	{
		writePad(1, pad, ' ');
		putc(arg);
		
		return this;
	}
	
	OutputStream write(char[] arg, int pad = 0)
	{
		writePad(arg.length, pad, ' ');
		
		foreach(char c; arg)
		{
			putc(c);
		}
		
		return this;
	}
	
	OutputStream write(bool arg, int pad = 0)
	{
		if(arg)
		{
			write("true", pad);
		}
		else
		{
			write("false", pad);
		}
		
		return this;
	}
	
	OutputStream write(bool[] arg)
	{
		write("[");
		
		foreach(size_t i, bool b; arg)
		{
			if(i != 0)
				write(", ");
				
			write(b);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(void* arg, int pad = 18)
	{
		write("0x");
		write(cast(ulong)arg, 16, pad-2);
		
		return this;
	}
	
	OutputStream write(void*[] arg)
	{
		write("[");
		
		foreach(size_t i, void* p; arg)
		{
			if(i != 0)
				write(", ");
				
			write(p);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(Object arg, int pad = 0)
	{
		write(arg.toString(), pad);
		
		return this;
	}
	
	OutputStream write(Object[] arg)
	{
		write("[");
		
		foreach(size_t i, Object o; arg)
		{
			if(i != 0)
				write(", ");
				
			write(o);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(ulong arg, int radix = 10, int pad = 0)
	{
		if(pad != 0 && pad > digits(arg, radix))
		{
			writePad(digits(arg, radix), pad, '0');
		}
		
		ulong d = arg%radix;
		
		arg -= d;
		arg /= radix;
		
		if(arg > 0)
		{
			write(arg, radix);
		}
		
		if(d < 10)
		{
			putc('0' + d);
		}
		else
		{
			putc('A' + (d - 10));
		}
		
		return this;
	}
	
	OutputStream write(ulong[] arg, int radix = 10)
	{
		write("[");
		
		foreach(size_t i, ulong a; arg)
		{
			if(i != 0)
				write(", ");
			
			write(a);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(uint arg, int radix = 10, int pad = 0)
	{
		write(cast(ulong)arg, radix, pad);
		
		return this;
	}
	
	OutputStream write(uint[] arg, int radix = 10)
	{
		write("[");
		
		foreach(size_t i, uint a; arg)
		{
			if(i != 0)
				write(", ");
			
			write(a);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(ushort arg, int radix = 10, int pad = 0)
	{
		write(cast(ulong)arg, radix, pad);
		
		return this;
	}
	
	OutputStream write(ushort[] arg, int radix = 10)
	{
		write("[");
		
		foreach(size_t i, ushort a; arg)
		{
			if(i != 0)
				write(", ");
			
			write(a);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(ubyte arg, int radix = 10, int pad = 0)
	{
		write(cast(ulong)arg, radix, pad);
		
		return this;
	}
	
	OutputStream write(ubyte[] arg, int radix = 10)
	{
		write("[");
		
		foreach(size_t i, ubyte a; arg)
		{
			if(i != 0)
				write(", ");
			
			write(a);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(long arg, int radix = 10, int pad = 0)
	{
		if(arg < 0)
		{
			write("-");
			pad--;
			arg = -arg;
		}
		
		write(cast(ulong)arg, radix, pad);
		
		return this;
	}
	
	OutputStream write(long[] arg, int radix = 10)
	{
		write("[");
		
		foreach(size_t i, long a; arg)
		{
			if(i != 0)
				write(", ");
			
			write(a, radix);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(int arg, int radix = 10, int pad = 0)
	{
		write(cast(long)arg, radix, pad);
		
		return this;
	}
	
	OutputStream write(int[] arg, int radix = 10)
	{
		write("[");
		
		foreach(size_t i, int a; arg)
		{
			if(i != 0)
				write(", ");
			
			write(a);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(short arg, int radix = 10, int pad = 0)
	{
		write(cast(long)arg, radix, pad);
		
		return this;
	}
	
	OutputStream write(short[] arg, int radix = 10)
	{
		write("[");
		
		foreach(size_t i, short a; arg)
		{
			if(i != 0)
				write(", ");
			
			write(a);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream write(byte arg, int radix = 10, int pad = 0)
	{
		write(cast(long)arg, radix, pad);
		
		return this;
	}
	
	OutputStream write(byte[] arg, int radix = 10)
	{
		write("[");
		
		foreach(size_t i, byte a; arg)
		{
			if(i != 0)
				write(", ");
			
			write(a);
		}
		
		write("]");
		
		return this;
	}
	
	OutputStream writef(...)
	{
		foreach(TypeInfo t; _arguments)
		{
			if(t.classinfo is typeid(Object).classinfo)
			{
				Object a = va_arg!(Object)(_argptr);
				write(a);
			}
			else if(t is typeid(char))
			{
				char a = va_arg!(char)(_argptr);
				write(a);
			}
			else if(t is typeid(ulong))
			{
				ulong a = va_arg!(ulong)(_argptr);
				write(a);
			}
			else if(t is typeid(uint))
			{
				uint a = va_arg!(uint)(_argptr);
				write(a);
			}
			else if(t is typeid(ushort))
			{
				ushort a = va_arg!(ushort)(_argptr);
				write(a);
			}
			else if(t is typeid(ubyte))
			{
				ubyte a = va_arg!(ubyte)(_argptr);
				
				write(a);
			}
			else if(t is typeid(long))
			{
				long a = va_arg!(long)(_argptr);
				
				write(a);
			}
			else if(t is typeid(int))
			{
				int a = va_arg!(int)(_argptr);
				
				write(a);
			}
			else if(t is typeid(short))
			{
				short a = va_arg!(short)(_argptr);
				
				write(a);
			}
			else if(t is typeid(byte))
			{
				byte a = va_arg!(byte)(_argptr);
				
				write(a);
			}
			else if(t.classinfo is typeid(Object[]).classinfo)
			{
				Object[] a = va_arg!(Object[])(_argptr);
				
				write(a);
			}
			else if(t == typeid(char[]))
			{
				char[] a = va_arg!(char[])(_argptr);
				write(a);
			}
			else if(t.classinfo.name == "TypeInfo_Pointer")
			{
				void* a = va_arg!(void*)(_argptr);
				write(a);
			}
			else
			{
				write(t.classinfo.name);
			}
		}
		
		return this;
	}
	
	OutputStream newline()
	{
		write('\n');
		
		return this;
	}
}
