/**
 * Screen device
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.dev.screen;

import std.mem;
import std.port;
import std.stdio;

class Screen : Output
{
    private byte* mem;
    private size_t cursor_x = 0;
    private size_t cursor_y = 0;
    
    public this(ulong screen_address)
    {
        mem = cast(byte*)screen_address;
    }
    
    public void putc(char c)
    {
        if(c == '\n')
        {
            cursor_x = 0;
            
            if(cursor_y >= 24)
            {
                memcpy(mem, mem + 80 * 2, 2 * 80 * 25);
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
            mem[2*pos] = ' ';
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
            mem[2*pos] = c;
            mem[2*pos + 1] = 0xF;
            cursor_x++;
        }

        if(cursor_x >= 80)
        {
            cursor_x = 0;
            
            if(cursor_y >= 24)
            {
                memcpy(mem, mem + 80 * 2, 2 * 80 * 25);
            }
            else
            {
                cursor_y++;
            }
        }

        updateCursor();
    }


    public void clear()
    {
        ushort u = cast(ushort)(0xF + (0x0 << 4));
        u = u<<8;

        // Clear one line beyond the screen, so we can just copy it up to get a clean line
        memsets(mem, u + ' ', 2 * 80 * (25 + 1));

        cursor_x = 0;
        cursor_y = 0;
        updateCursor();
    }

    private void updateCursor()
    {
        uint temp = cursor_y * 80 + cursor_x;

        outp(0x3D4, 14);
        outp(0x3D5, temp >> 8);
        outp(0x3D4, 15);
        outp(0x3D5, temp);
    }
}
