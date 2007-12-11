

module std.io.CharStream;

import std.io.Stream;
import std.integer;
import std.collection.Stack;
import std.c.stdarg;

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
			
			if(ret[i] == '\b')
				i--;
		}
		
		return ret;
	}
	
	char[] readln(CharOutputStream output = null, char delimiter = '\n')
	{
		scope auto buf = new Stack!(char);
			
		char c;
		
		do
		{
			c = read();
			
			if(c == '\b' && buf.size() > 0)
			{
				buf.pop();
				
				if(output !is null)
					output.write(c);
			}
			else if(c != '\b')
			{
				buf.push(c);
				
				if(output !is null)
					output.write(c);
			}
		
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
	
	/**
     * Print a character repeatedly
     *
     * Used by doFormat for padding values
     *
     * Params:
     *  c = character to print
     *  n = number of times to print c
     */
    private void pad(char c, long n)
    {
        if(n == 0)
            return;

        for(long i = 0; i<n; i++)
        {
            write(c);
        }
    }

	public CharOutputStream writef(...)
	{
		doFormat(_arguments, _argptr);
		
		return this;
	}
	
	/**
     * Parse a set of arguments and print their contents to screen
     *
     * Some types have default display options (strings, pointers, etc...)
     *
     * Params:
     *  args = array of argument types
     *  argptr = pointer used to access the variable argument list
     */
    private void doFormat(TypeInfo[] args, va_list argptr)
    {
        // Iterate through arguments
        for(int i=0; i<args.length; i++)
        {
            // Parse a string for formatting symbols
            if(args[i] == typeid(char[]))
            {
                // Read the string argument
                char[] a = va_arg!(char[])(argptr);

                // Iterate through string
                for(int j=0; j<a.length; j++)
                {
                    // If % is found, look for formatting information
                    if(a[j] == '%')
                    {
                        bool parse = true;
                        bool prefix = false;
                        long padlen = 0;
                        char padchar = ' ';

                        // Loop until the format has been completely specified
                        while(parse)
                        {
                            j++;

                            // Just print %
                            if(a[j] == '%')
                            {
                                write('%');

                                parse = false;
                            }
                            // A pad character or pad length is being specified
                            else if(a[j] >= '0' && a[j] <= '9')
                            {
                                // If the pad length starts with 0, set the pad character to '0'
                                if(a[j] == '0' && padlen == 0)
                                {
                                    padchar = '0';
                                }
                                // Add digits to the pad length
                                else
                                {
                                    padlen *= 10;

                                    if(a[j] == '1')
                                        padlen += 1;
                                    else if(a[j] == '2')
                                        padlen += 2;
                                    else if(a[j] == '3')
                                        padlen += 3;
                                    else if(a[j] == '4')
                                        padlen += 4;
                                    else if(a[j] == '5')
                                        padlen += 5;
                                    else if(a[j] == '6')
                                        padlen += 6;
                                    else if(a[j] == '7')
                                        padlen += 7;
                                    else if(a[j] == '8')
                                        padlen += 8;
                                    else if(a[j] == '9')
                                        padlen += 9;
                                }
                            }
                            // Pad is specified by the next argument
                            else if(a[j] == '*')
                            {
                                i++;
                                if(args[i] == typeid(ubyte) || args[i] == typeid(byte))
                                {
                                    ubyte x = va_arg!(ubyte)(argptr);
                                    padlen = x;
                                }
                                else if(args[i] == typeid(ushort) || args[i] == typeid(short))
                                {
                                    ushort x = va_arg!(ushort)(argptr);
                                    padlen = x;
                                }
                                else if(args[i] == typeid(uint) || args[i] == typeid(int))
                                {
                                    uint x = va_arg!(uint)(argptr);
                                    padlen = x;
                                }
                                else if(args[i] == typeid(ulong) || args[i] == typeid(long))
                                {
                                    ulong x = va_arg!(ulong)(argptr);
                                    padlen = x;
                                }
                                else
                                {
                                    assert(0, "Invalid parameter type for * format flag.");
                                }
                            }
                            // Include the '0x' prefix on hexadecimal numbers
                            else if(a[j] == '#')
                            {
                                prefix = true;
                            }
                            // Print a signed integer
                            else if(a[j] == 'd' || a[j] == 'i')
                            {
                                long x;

                                i++;

                                if(args[i] == typeid(ubyte) || args[i] == typeid(byte))
                                    x = va_arg!(byte)(argptr);

                                else if(args[i] == typeid(ushort) || args[i] == typeid(short))
                                    x = va_arg!(short)(argptr);

                                else if(args[i] == typeid(uint) || args[i] == typeid(int))
                                    x = va_arg!(int)(argptr);

                                else if(args[i] == typeid(ulong) || args[i] == typeid(long))
                                    x = va_arg!(long)(argptr);

                                else
                                    assert(0, "Invalid parameter type for %u format flag.");

                                if(x < 0)
                                {
                                    write('-');
                                    x = -x;
                                }
                                
                                ulong y = cast(ulong)x;

                                char[] str = new char[digits(y)];

                                itoa(y, str.ptr);

                                write(str);
                                
                                delete str;

                                parse = false;
                            }
                            // Print an unsigned integer
                            else if(a[j] == 'u')
                            {
                                ulong x;

                                i++;

                                if(args[i] == typeid(ubyte) || args[i] == typeid(byte))
                                    x = va_arg!(ubyte)(argptr);

                                else if(args[i] == typeid(ushort) || args[i] == typeid(short))
                                    x = va_arg!(ushort)(argptr);

                                else if(args[i] == typeid(uint) || args[i] == typeid(int))
                                    x = va_arg!(uint)(argptr);

                                else if(args[i] == typeid(ulong) || args[i] == typeid(long))
                                    x = va_arg!(ulong)(argptr);

                                else
                                    assert(0, "Invalid parameter type for %u format flag.");

                                char[] str = new char[digits(x)];

                                itoa(x, str.ptr);

                                write(str);
                                
                                delete str;

                                parse = false;
                            }
                            // Print an unsigned hexadecimal integer
                            else if(a[j] == 'x' || a[j] == 'X')
                            {
                                bool uc = true;

                                if(a[j] == 'x')
                                    uc = false;

                                if(prefix)
                                    write("0x");

                                ulong x;

                                i++;

                                if(args[i] == typeid(ubyte) || args[i] == typeid(byte))
                                    x = va_arg!(ubyte)(argptr);

                                else if(args[i] == typeid(ushort) || args[i] == typeid(short))
                                    x = va_arg!(ushort)(argptr);

                                else if(args[i] == typeid(uint) || args[i] == typeid(int))
                                    x = va_arg!(uint)(argptr);

                                else if(args[i] == typeid(ulong) || args[i] == typeid(long))
                                    x = va_arg!(ulong)(argptr);

                                else
                                    assert(0, "Invalid parameter type for %x format flag.");

                                long len = digits(x, 16);
                                char[] str = new char[len];

                                itoa(x, str.ptr, 16, uc);

                                pad(padchar, padlen - len);
                                write(str);
                                
                                delete str;

                                parse = false;
                            }
                            // Print a string (don't parse for formatting)
                            else if(a[j] == 's')
                            {
                                i++;

                                if(args[i] == typeid(char[]))
                                {
                                    char[] x = va_arg!(char[])(argptr);

                                    ulong len = x.length;

                                    pad(padchar, padlen - len);

                                    write(x);

                                    parse = false;
                                }
                                else
                                {
                                    assert(0, "Invalid parameter type for %s format flag.");
                                }
                            }
                        }
                    }
                    else
                    {
                        write(a[j]);
                    }
                }
            }
            else if((cast(TypeInfo_Pointer)args[i]) !is null)
            {
                ulong x = va_arg!(ulong)(argptr);
                write("0x");

                long len = digits(x, 16);
                char[16] str;

                pad('0', 16 - len);
                itoa(x, str.ptr, 16, true);

                write(str);
            }
            else if(args[i].classinfo is typeid(Object).classinfo)
            {
                Object a = va_arg!(Object)(argptr);
                write(a.toString());
            }
            else
            {
                ulong size = args[i].tsize();

                writef("unknown type (size: %X)", args[i].tsize());

                if(size == ubyte.sizeof)
                    va_arg!(ubyte)(argptr);

                else if(size == ushort.sizeof)
                    va_arg!(ushort)(argptr);

                else if(size == uint.sizeof)
                    va_arg!(uint)(argptr);

                else if(size == ulong.sizeof)
                    va_arg!(ulong)(argptr);

                else
                    assert(0, "Unhandled argument type");
            }
        }
    }

	
	CharOutputStream newline()
	{
		write('\n');
		
		return this;
	}
}
