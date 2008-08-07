/**
 * GDT Abstraction
 *
 * Copyright: 2008 The Neptune Project
 */

module util.arch.gdt;

import util.arch.descriptor;

/**
 * GDT abstraction
 */
struct GDT
{
    ulong* data;
    private size_t index = 0;
    
    /**
     * Initialize the GDT data
     */
    public void init(void* ptr)
    {
        index = 0;
        data = cast(ulong*)ptr;
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
        DTPtr gdtp = DTPtr(index * 8 - 1, cast(ulong)data);

        asm
        {
            "cli";
            "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
        }
    }
}
