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

interface Output
{
    void putc(char c);
}

interface Input
{
    char getc();
}

Output stdout;
Output stderr;
Input stdin;

void write(char c)
{
    write(stdout, c);
}

void writeln(char c)
{
    writeln(stdout, c);
}

void write(Output o, char c)
{
    o.putc(c);
}

void writeln(Output o, char c)
{
    o.putc(c);
    o.putc('\n');
}

void write(char[] str)
{
    write(stdout, str);
}

void writeln(char[] str)
{
    writeln(stdout, str);
}

void write(Output o, char[] str)
{
    foreach(c; str)
    {
        o.putc(c);
    }
}

void writeln(Output o, char[] str)
{
    write(o, str);
    o.putc('\n');
}

void writef(...)
{
    if(_arguments[0] == typeid(Output))
    {
        Output o = va_arg!(Output)(_argptr);
        
        doFormat(o, _arguments[1..length], _argptr);
    }
    else
    {
        doFormat(stdout, _arguments, _argptr);
    }
}

void writefln(...)
{
    if(_arguments[0] == typeid(Output))
    {
        Output o = va_arg!(Output)(_argptr);
        
        doFormat(o, _arguments[1..length], _argptr);
        
        o.putc('\n');
    }
    else
    {
        doFormat(stdout, _arguments, _argptr);
        stdout.putc('\n');
    }
}

private void doFormat(Output o, TypeInfo[] args, va_list argptr)
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
                            o.putc('%');

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
                                    
                                    write(o, "0x");
                                    write(o, buf);
                                }
                                else
                                {
                                    char buf[32];
                                    if(prefix)
                                        write(o, "0x");
                                    write(o, itoa(x, buf, 16));
                                }
                            }
                            else
                            {
                                char buf[32];
                                write(o, itoa(x, buf, 10));
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

                                write(o, x);

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
                    o.putc(a[j]);
                }
            }
        }
        else
        {
            assert(false, "Unhandled argument type");
        }
    }
}
