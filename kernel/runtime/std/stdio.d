/**
 * Standard I/O operations
 *
 * Copyright: 2008 The Neptune Project
 */
 
module std.stdio;

import kernel.arch.native;

import std.integer;
import std.stdarg;

/**
 * Write a single character to screen
 *
 * Params:
 *  c = character to write
 */
void write(char c)
{
    putc(c);
}

/**
 * Write a single character to screen, followed by a newline
 *
 * Params:
 *  c = character to write
 */
void writeln(char c)
{
    putc(c);
    putc('\n');
}

/**
 * Write a string of characters to screen
 *
 * Params:
 *  str = string to write
 */
void write(char[] str)
{
    foreach(c; str)
    {
        putc(c);
    }
}

/**
 * Write a string of characters to screen, followed by a newline
 *
 * Params:
 *  str = string to write
 */
void writeln(char[] str)
{
    write(str);
    putc('\n');
}

/**
 * Write a formatted string to screen
 */
void writef(...)
{
    doFormat(_arguments, _argptr);
}

/**
 * Write a formatted string to screen, followed by a newline
 */
void writefln(...)
{
    doFormat(_arguments, _argptr);
    putc('\n');
}

/**
 * Parse a list of arguments to writef or writefln and perform the
 * formatting operations specified in all format strings
 *
 * Params:
 *  args = array of typeinfo paramters for arguments
 *  argptr = argptr used to reference values for all arguments
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
