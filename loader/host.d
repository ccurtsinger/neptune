/**
 * Required support functions for the Triton
 * runtime library
 *
 * Copyright: 2008 The Neptune Project
 */

module loader.host;

import std.port;
import std.mem;
import std.stdio;

import util.arch.paging;

/// Memory address of the last allocated physical page
uint nextPage;

private size_t cursor_x = 0;
private size_t cursor_y = 0;
private char* mem = cast(char*)0xB8000;

extern(C) void* m_alloc(size_t size)
{
    nextPage += FRAME_SIZE;
	return cast(void*)nextPage;
}

extern(C) size_t p_alloc()
{
    nextPage += FRAME_SIZE;
	return nextPage;
}

extern(C) size_t m_size(void* p)
{
    return FRAME_SIZE;
}

extern(C) void m_free(void* p)
{
    // Do nothing here
}

extern(C) void* ptov(size_t s)
{
    return cast(void*)s;
}

extern(C) size_t vtop(void* p)
{
    return cast(size_t)p;
}

extern(C) void _d_error(char[] msg, char[] file, size_t line)
{
    write(msg);
	
	if(file !is null && line > 0)
	{
	    writef(" (%s, line %u)", file, line);
	}
	
	for(;;){}
}

extern(C) void _d_abort()
{
    _d_error("Aborted", null, 0);
}

class Screen : Output
{
    public void putc(char c)
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
            cursor_y++;
        }

        if(cursor_y >= 25)
        {
            // Copy a screen up, but offset by one line.  Move the line after the console up one (we cleared it in clear_screen())
            memcpy(mem, mem + 80 * 2, 2 * 80 * 25);
            cursor_y--;
        }

        updateCursor();
    }
}


public void clear()
{
    ushort u = cast(ushort)(0xF + (0x0 << 4));
    u = u<<8;

    // Clear one line beyond the screen, so we can just copy it up to get a clean line
    memsets(cast(byte*)mem, u + ' ', 2 * 80 * (25 + 1));

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
