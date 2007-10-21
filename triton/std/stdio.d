module std.stdio;

import std.stdarg;

extern(C) void putc(char c);

void write(char[] s)
{
    foreach(char c; s)
    {
        putc(c);
    }
}

void writeln(char[] s)
{
    write(s);
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

void print_uint_dec(ulong i, int pad = 0, char padchar = '0')
{
    print_uint(i, 10, true, pad, padchar);
}

void print_uint_hex(ulong i, int pad = 0, char padchar = '0')
{
    print_uint(i, 16, true, pad, padchar);
}

void print_int(long i, uint base, bool uc = true, int pad = 0, char padchar = '0')
{
    if(i < 0)
    {
        putc('-');
        if(pad != 0)
            pad--;

        i = -i;
    }

    print_uint(i, base, uc, pad, padchar);
}

void print_uint(ulong i, uint base, bool uc = true, int pad = 0, char padchar = '0')
{
    ulong t = 1;

    for(int l=0; l<pad; l++)
    {
        if(i < t-1)
            putc(padchar);

        t *= base;
    }

    if(i < base)
    {
        if(i < 10)
        {
            putc(i+'0');
        }
        else
        {
            if(uc == true)
            {
                putc((i-10)+'A');
            }
            else
            {
                putc((i-10)+'a');
            }
        }

        return;
    }
    else
    {
        byte digit = i%base;
        i -= digit;
        i /= base;

        print_uint(i, base, uc);

        print_uint(digit, base, uc);
    }
}

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
                    ulong pad = 0;
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
                            if(a[j] == '0' && pad == 0)
                            {
                                padchar = '0';
                            }
                            // Add digits to the pad length
                            else
                            {
                                pad *= 10;

                                if(a[j] == '1')
                                    pad += 1;
                                else if(a[j] == '2')
                                    pad += 2;
                                else if(a[j] == '3')
                                    pad += 3;
                                else if(a[j] == '4')
                                    pad += 4;
                                else if(a[j] == '5')
                                    pad += 5;
                                else if(a[j] == '6')
                                    pad += 6;
                                else if(a[j] == '7')
                                    pad += 7;
                                else if(a[j] == '8')
                                    pad += 8;
                                else if(a[j] == '9')
                                    pad += 9;
                            }
                        }
                        // Pad is specified by the next argument
                        else if(a[j] == '*')
                        {
                            i++;
                            if(args[i] == typeid(ubyte) || args[i] == typeid(byte))
                            {
                                ubyte x = va_arg!(ubyte)(argptr);
                                pad = x;
                            }
                            else if(args[i] == typeid(ushort) || args[i] == typeid(short))
                            {
                                ushort x = va_arg!(ushort)(argptr);
                                pad = x;
                            }
                            else if(args[i] == typeid(uint) || args[i] == typeid(int))
                            {
                                uint x = va_arg!(uint)(argptr);
                                pad = x;
                            }
                            else if(args[i] == typeid(ulong) || args[i] == typeid(long))
                            {
                                ulong x = va_arg!(ulong)(argptr);
                                pad = x;
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
                        }
                        // Print an unsigned integer
                        else if(a[j] == 'u')
                        {
                            i++;
                            if(args[i] == typeid(ubyte) || args[i] == typeid(byte))
                            {
                                ubyte x = va_arg!(ubyte)(argptr);
                                print_uint(x, 10, true, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(ushort) || args[i] == typeid(short))
                            {
                                ushort x = va_arg!(ushort)(argptr);
                                print_uint(x, 10, true, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(uint) || args[i] == typeid(int))
                            {
                                uint x = va_arg!(uint)(argptr);
                                print_uint(x, 10, true, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(ulong) || args[i] == typeid(long))
                            {
                                ulong x = va_arg!(ulong)(argptr);
                                print_uint(x, 10, true, pad, padchar);

                                parse = false;
                            }
                            else
                            {
                                assert(0, "Invalid parameter type for %u format flag.");
                            }
                        }
                        // Print an unsigned hexadecimal integer
                        else if(a[j] == 'x' || a[j] == 'X')
                        {
                            bool uc = true;

                            if(a[j] == 'x')
                                uc = false;

                            if(prefix)
                                write("0x");

                            i++;

                            if(args[i] == typeid(ubyte) || args[i] == typeid(byte))
                            {
                                ubyte x = va_arg!(ubyte)(argptr);
                                print_uint(x, 16, uc, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(ushort) || args[i] == typeid(short))
                            {
                                ushort x = va_arg!(ushort)(argptr);
                                print_uint(x, 16, uc, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(uint) || args[i] == typeid(int))
                            {
                                uint x = va_arg!(uint)(argptr);
                                print_uint(x, 16, uc, pad, padchar);

                                parse = false;
                            }
                            else if(args[i] == typeid(ulong) || args[i] == typeid(long))
                            {
                                ulong x = va_arg!(ulong)(argptr);
                                print_uint(x, 16, uc, pad, padchar);

                                parse = false;
                            }
                            else
                            {
                                assert(0, "Invalid parameter type for %x format flag.");
                            }
                        }
                        // Print a string (don't parse for formatting)
                        else if(a[j] == 's')
                        {
                            i++;

                            if(args[i] == typeid(char[]))
                            {
                                char[] x = va_arg!(char[])(argptr);

                                ulong len = x.length;

                                while(len < pad)
                                {
                                    len++;
                                    putc(padchar);
                                }

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
            print_uint(x, 16, true, 16, '0');
        }
        else
        {
            ulong size = args[i].tsize();

            write("unknown type (size: ");
            print_uint_dec(size);
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
