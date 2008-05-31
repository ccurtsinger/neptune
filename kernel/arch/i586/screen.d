module kernel.arch.i586.screen;

version(arch_i586):

import std.port;
import std.mem;

byte* screen_mem;
size_t cursor_x;
size_t cursor_y;

void print(char[] str)
{
    foreach(c; str)
    {
        putc(c);
    }
}

void println(char[] str)
{
    print(str);
    putc('\n');
}

extern(C) void putc(char c)
{
    if(c == '\n')
    {
        cursor_x = 0;
        
        if(cursor_y >= 24)
        {
            memcpy(screen_mem, screen_mem + 80 * 2, 2 * 80 * 25);
        }
        else
        {
            cursor_y++;
        }
    }
    else if(c == '\b')
    {
        if(cursor_x > 0)
        {
            cursor_x--;
        }
        else
        {
            cursor_x = 80-1;
            cursor_y--;
        }

        uint pos = cursor_y*80 + cursor_x;
        screen_mem[2*pos] = ' ';
    }
    else if(c == '\t')
    {
        uint t = 4 - cursor_x%4;

        if(t == 0)
        {
            t = 4;
        }

        cursor_x += t;
    }
    else if(c != '\0')
    {
        uint pos = cursor_y * 80 + cursor_x;
        screen_mem[2*pos] = c;
        screen_mem[2*pos + 1] = 0xF;
        cursor_x++;
    }

    if(cursor_x >= 80)
    {
        cursor_x = 0;
        
        if(cursor_y >= 24)
        {
            memcpy(screen_mem, screen_mem + 80 * 2, 2 * 80 * 25);
        }
        else
        {
            cursor_y++;
        }
    }

    update_cursor();
}

void clear_screen()
{
    ushort u = cast(ushort)(0xF + (0x0 << 4));
    u = u<<8;

    // Clear one line beyond the screen, so we can just copy it up to get a clean line
    memsets(screen_mem, u + ' ', 2 * 80 * (25 + 1));

    cursor_x = 0;
    cursor_y = 0;
    
    update_cursor();
}

void update_cursor()
{
    uint temp = cursor_y * 80 + cursor_x;

    outp(0x3D4, 14);
    outp(0x3D5, temp >> 8);
    outp(0x3D4, 15);
    outp(0x3D5, temp);
}
