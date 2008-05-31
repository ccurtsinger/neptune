/**
 * Standard I/O operations
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */
 
module std.stdio;

import std.integer;
import std.stdarg;

extern(C) void putc(char c);

void write(char c)
{
    putc(c);
}

void writeln(char c)
{
    putc(c);
    putc('\n');
}

void write(char[] str)
{
    foreach(c; str)
    {
        putc(c);
    }
}

void writeln(char[] str)
{
    write(str);
    putc('\n');
}

void writef(...)
{
    doFormat(_arguments, _argptr);
}

void writefln(...)
{
    
    doFormat(_arguments, _argptr);
    putc('\n');
}

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
                        // Include the '0x' prefix on hexadecimal numbers
                        else if(a[j] == '#')
                        {
                            prefix = true;
                        }
                        // Print an unsigned integer
                        else if(a[j] == 'u' || a[j] == 'x' || a[j] == 'X' || a[j] == 'p')
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
                                
                            else if((cast(TypeInfo_Pointer)args[i]) !is null)
                                x = va_arg!(size_t)(argptr);

                            else
                                assert(0, "Invalid parameter type for %u format flag.");

                            if(a[j] == 'x' || a[j] == 'X' || a[j] == 'p')
                            {
                                if(a[j] == 'p')
                                {
                                    char buf[size_t.sizeof*2];
                                    itoa(x, buf, 16);
                                    
                                    write("0x");
                                    write(buf);
                                }
                                else
                                {
                                    char buf[32];
                                    if(prefix)
                                        write("0x");
                                    write(itoa(x, buf, 16));
                                }
                            }
                            else
                            {
                                char buf[32];
                                write(itoa(x, buf, 10));
                            }

                            parse = false;
                        }
                        // Print a string (don't parse for formatting)
                        else if(a[j] == 's')
                        {
                            i++;

                            if(args[i] == typeid(char[]))
                            {
                                char[] x = va_arg!(char[])(argptr);

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
                    putc(a[j]);
                }
            }
        }
        else
        {
            assert(false, "Unhandled argument type");
        }
    }
}
