/**
 * GDT Abstraction
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module arch.x86_64.gdt;

import arch.x86_64.descriptor;

/**
 * GDT abstraction
 */
struct GDT
{
    ulong[256] data;
    private size_t index = 0;
    
    /**
     * Initialize the GDT data
     */
    public void init()
    {
        index = 0;
    }
    
    /**
     * Return a pointer to the next free entry in the descriptor table
     */
    public T* getEntry(T)()
    {
        size_t i;
        
        i = index;
        index += T.sizeof/ulong.sizeof;
        
        return cast(T*)&(data[i]);
    }
    
    /**
     * Get the selector index for the next available entry
     */
    public ushort getSelector()
    {
        return ulong.sizeof * index;
    }
    
    /**
     * Load the GDT
     */
    public void install()
    {
        DTPtr gdtp;
        
        gdtp.limit = index * 8 - 1;
        gdtp.address = data.ptr;

        asm
        {
            "cli";
            "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
        }
    }
}
