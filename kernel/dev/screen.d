/**
 * Basic abstraction for a memory-mapped screen
 *
 * Authors: Charlie Curtsinger
 * Date: October 29th, 2007
 * Version: 0.1a
 */

module kernel.dev.screen;

import std.port;
import std.mem;

/// Possible foreground and background colors
enum Color
{
    black,
    blue,
    green,
    cyan,
    red,
    magenta,
    brown,
    lightgrey,
    darkgrey,
    lightblue,
    lightgreen,
    lightcyan,
    lightred,
    lightmagenta,
    lightbrown,
    white,
    none
}

/**
 * Screen abstraction
 */
class Screen
{
    /// Base address of the screen memory
    private char* mem;
    
    /// Screen width in characters
    private size_t width;
    
    /// Screen height in characters
    private size_t height;
    
    /// Tab size in characters
    private size_t tabSize;
    
    /// Cursor X position
    private size_t cursor_x;
    
    /// Cursor Y position
    private size_t cursor_y;
    
    /**
     * Initialize a new Screen object
     *
     * Params:
     *  mem = base address of screen memory
     *  width = width of the screen
     *  height = height of the screen
     *  tabSize = tab size
     */
    public this(char* mem = cast(char*)0xFFFF8300000B8000, size_t width = 80, size_t height = 25, size_t tabSize = 4)
    {
        this.mem = mem;
        this.width = width;
        this.height = height;
        this.tabSize = tabSize;
        
        cursor_x = 0;
        cursor_y = 0;
    }

    /**
     * Write a character to screen and update cursor position
     *
     * Params:
     *  c = character to write
     *  fg = foreground color for the character (not applied to special characters)
     *  bg = background color for the character (not applied to special characters)
     */
    public void putc(char c, Color fg = Color.none, Color bg = Color.none)
    {
        char color = mem[1];
        
        if(fg != Color.none)
        {
            color = (color & 0xF0) + fg;
        }
        
        if(bg != Color.none)
        {
            color = (color * 0x0F) + (bg << 4);
        }
        
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
                cursor_x = width-1;
                cursor_y--;
            }
            
            uint pos = cursor_y*width + cursor_x;
            mem[2*pos] = ' ';
        }
        else if(c == '\t')
        {
            uint t = tabSize - cursor_x%tabSize;

            if(t == 0)
            {
                t = tabSize;
            }

            cursor_x += t;
        }
        else if(c != '\0')
        {
            uint pos = cursor_y * width + cursor_x;
            mem[2*pos] = c;
            mem[2*pos + 1] = color;
            cursor_x++;
        }

        if(cursor_x >= width)
        {
            cursor_x = 0;
            cursor_y++;
        }

        if(cursor_y >= width)
        {
            // Copy a screen up, but offset by one line.  Move the line after the console up one (we cleared it in clear_screen())
            memcpy(mem, mem + width * 2, 2 * width * height);
            cursor_y--;
        }

        updateCursor();
    }
    
    /**
     * Clear the screen and reset cursor to top left
     *
     * Params:
     *  fg = default foreground color for the screen after clearing
     *  bg = default background color for the screen after clearing
     */
    public void clear(Color fg = Color.white, Color bg = Color.black)
    {
        ushort u = cast(ushort)(fg + (bg << 4));
        u = u<<8;
        
        // Clear one line beyond the screen, so we can just copy it up to get a clean line
        memsets(cast(byte*)mem, u + ' ', 2 * width * (height + 1));

        cursor_x = 0;
        cursor_y = 0;
        updateCursor();
    }

    /**
     * Move the cursor to stored position
     */
    private void updateCursor()
    {
        uint temp = cursor_y * width + cursor_x;

        outp(0x3D4, 14);
        outp(0x3D5, temp >> 8);
        outp(0x3D4, 15);
        outp(0x3D5, temp);
    }

    /**
     * Set the cursor position
     *
     * Params:
     *  x = new x position
     *  y = new y position
     */
    public void setCursor(size_t x, size_t y)
    {
        cursor_x = x;
        cursor_y = y;
        updateCursor();
    }
}
