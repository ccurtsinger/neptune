module dev.screen;

import dev.port;
import mem.util;

import std.stdarg;

const char* SCREEN_MEM = cast(char*)0xFFFF8300000B8000;
const uint SCREEN_WIDTH = 80;
const uint SCREEN_HEIGHT = 25;
const uint TAB_SIZE = 4;

ubyte cursor_x = 0;
ubyte cursor_y = 0;

void printc(char c)
{
    if(c == '\n')
    {
        cursor_x = 0;
        cursor_y++;
    }
    else if(c == '\b')
    {
        if(cursor_x > 0)
        {
            cursor_x--;

            uint pos = cursor_y*SCREEN_WIDTH + cursor_x;
            SCREEN_MEM[2*pos] = ' ';
        }
    }
    else if(c == '\t')
    {
        uint t = TAB_SIZE - cursor_x%TAB_SIZE;

        if(t == 0)
        {
            t = TAB_SIZE;
        }

        cursor_x += t;
    }
    else if(c != '\0')
    {
        uint pos = cursor_y*SCREEN_WIDTH + cursor_x;
        SCREEN_MEM[2*pos] = c;
        cursor_x++;
    }

    if(cursor_x >= SCREEN_WIDTH)
    {
        cursor_x = 0;
        cursor_y++;
    }

    if(cursor_y >= SCREEN_HEIGHT)
    {
        // Copy a screen up, but offset by one line.  Move the line after the console up one (we cleared it in clear_screen())
        memcpy(SCREEN_MEM, SCREEN_MEM + SCREEN_WIDTH*2, 2*SCREEN_WIDTH*SCREEN_HEIGHT);
        cursor_y--;
    }

    draw_cursor();
}

void print(char[] s)
{
    foreach(char c; s)
    {
        printc(c);
    }
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
        printc('-');
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
            printc(padchar);

        t *= base;
    }

    if(i < base)
    {
        if(i < 10)
        {
            printc(i+'0');
        }
        else
        {
            if(uc == true)
            {
                printc((i-10)+'A');
            }
            else
            {
                printc((i-10)+'a');
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

void clear_screen()
{
    // Clear one line beyond the screen, so we can just copy it up to get a clean line
    memsets(cast(byte*)SCREEN_MEM, 0x0F00 + ' ', 2*SCREEN_WIDTH*(SCREEN_HEIGHT+1));

    cursor_x = 0;
    cursor_y = 0;
    draw_cursor();
}

void draw_cursor()
{
    uint temp = cursor_y * SCREEN_WIDTH + cursor_x;

    outp(0x3D4, 14);
    outp(0x3D5, temp >> 8);
    outp(0x3D4, 15);
    outp(0x3D5, temp);
}

void set_cursor(ubyte x, ubyte y)
{
    cursor_x = x;
    cursor_y = y;
    draw_cursor();
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
                            printc('%');

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
                                print("0x");

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
                                    printc(padchar);
                                }

                                print(x);

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
                    printc(a[j]);
            }
        }
        // Display pointers as a hexadecimal number extended to 16 digits
        //  Because classes are reference types, treat them like pointers
        else if((cast(TypeInfo_Pointer)args[i]) !is null ||
                (cast(TypeInfo_Class)args[i]) !is null)
        {
            ulong x = va_arg!(ulong)(argptr);
            print("0x");
            print_uint(x, 16, true, 16, '0');
        }
        else
        {
            ulong size = args[i].tsize();

            print("unknown type (size: ");
            print_uint_dec(size);
            print(")");

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

void writefln(...)
{
    doFormat(_arguments, _argptr);
    printc('\n');
}

void writef(...)
{
    doFormat(_arguments, _argptr);
}
