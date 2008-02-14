
module std.stdio;

import std.integer;
import std.stdarg;

void write(char[] str, size_t len = 0, char padchar = ' ')
{
    for(size_t i=str.length; i<len; i++)
    {
        _d_putc(padchar);
    }
    
    foreach(c; str)
    {
        _d_putc(c);
    }
}

void writeln(char[] str, size_t len = 0, char padchar = ' ')
{
    write(str, len, padchar);
    _d_putc('\n');
}

void writef(...)
{
    doFormat(&_putc, _arguments, _argptr);
}

void writefln(...)
{
    doFormat(&_putc, _arguments, _argptr);
    _d_putc('\n');
}

private void _putc(char c)
{
    _d_putc(c);
}

private void doFormat(void function(char) putc, TypeInfo[] args, va_list argptr)
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
                            putc('%');

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
                                putc('-');
                                x = -x;
                            }
                            
                            ulong y = cast(ulong)x;

                            puti(putc, y);

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

                            puti(putc, x);

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

                            puti(putc, x, 16, uc, padlen, padchar);

                            parse = false;
                        }
                        // Print a string (don't parse for formatting)
                        else if(a[j] == 's')
                        {
                            i++;

                            if(args[i] == typeid(char[]))
                            {
                                char[] x = va_arg!(char[])(argptr);

                                write(x, padlen, padchar);

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
                    putc(a[j]);
                }
            }
        }
        else if((cast(TypeInfo_Pointer)args[i]) !is null)
        {
            ulong x = va_arg!(ulong)(argptr);
            write("0x");

            puti(putc, x, 16, true, 8*size_t.sizeof);
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
