module kernel.dev.screen;

import std.port;
import std.mem;

const char* SCREEN_MEM = cast(char*)0xFFFF8300000B8000;
const uint SCREEN_WIDTH = 80;
const uint SCREEN_HEIGHT = 25;
const uint TAB_SIZE = 4;

ubyte cursor_x = 0;
ubyte cursor_y = 0;

extern(C) void putc(char c)
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
        }
        else
        {
        	cursor_x = SCREEN_WIDTH-1;
        	cursor_y--;
        }
        
        uint pos = cursor_y*SCREEN_WIDTH + cursor_x;
		SCREEN_MEM[2*pos] = ' ';
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
