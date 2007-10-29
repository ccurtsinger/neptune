module std.stdio;

import std.integer;
import std.stdarg;

private extern(C) void putc(char c);

/**
 * Write a string to screen
 */
void write(char[] s)
{
    foreach(char c; s)
    {
        putc(c);
    }
}
/**
 * Write a string to screen, followed by a newline
 */
void writeln(char[] s)
{
    write(s);
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
 * Print 'c' 'n' times
 *
 * Used by doFormat for padding values
 */
void pad(char c, long n)
{
    if(n == 0)
        return;

    for(long i = 0; i<n; i++)
    {
        putc(c);
    }
}

/**
 * Parse a set of arguments using standard formatting rules for printf
 *
 * Some types have default display options (strings, pointers, etc...)
 */
void doFormat(TypeInfo[] args, va_list argptr)
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
                        /*else if(a[j] == 'd' || a[j] == 'i')
                        {
                            i++;
                            if(args[i] == typeid(ubyte) || args[i] == typeid(byte))
                            {
                                byte x = va_arg!(byte)(argptr);
                                print_int(x, 10, true, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(ushort) || args[i] == typeid(short))
                            {
                                short x = va_arg!(short)(argptr);
                                print_int(x, 10, true, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(uint) || args[i] == typeid(int))
                            {
                                int x = va_arg!(int)(argptr);
                                print_int(x, 10, true, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(ulong) || args[i] == typeid(long))
                            {
                                long x = va_arg!(long)(argptr);
                                print_int(x, 10, true, pad, padchar);

                                parse = false;
                            }
                            else
                            {
                                assert(0, "Invalid parameter type for %d format flag.");
                            }
                        }*/
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
                    putc(a[j]);
            }
        }
        // Display pointers as a hexadecimal number extended to 16 digits
        //  Because classes are reference types, treat them like pointers
        else if((cast(TypeInfo_Pointer)args[i]) !is null ||
                (cast(TypeInfo_Class)args[i]) !is null)
        {
            ulong x = va_arg!(ulong)(argptr);
            write("0x");

            long len = digits(x, 16);
            char[16] str;

            pad('0', 16 - len);
            itoa(x, str.ptr, 16, true);

            write(str);
        }
        else
        {
            ulong size = args[i].tsize();

            write("unknown type (size: ");
            //print_uint_dec(size);
            write(")");

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
