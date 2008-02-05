/**
 * Abstraction for pages and a page table
 *
 * Authors: Charlie Curtsinger
 * Date: January 15th, 2008
 * Version: 0.2a
 */

module kernel.arch.PageTable;

import std.bitarray;
import std.integer;
import std.stdmem;
import kernel.arch.Arch;

/**
 * Page table entry abstraction
 */
struct Page
{
    ulong data;
    
    /**
     * Initialize page data
     */
    static Page opCall()
    {
        Page p;
        p.present = false;
        return p;
    }
    
    /**
     * Get the page present bit state
     */
    bool present()
    {
        return BitArray(&data, 64)[0];
    }
    
    /**
     * Set the page present bit state
     */
    void present(bool b)
    {
        BitArray(&data, 64)[0] = b;
    }
    
    /**
     * Get the page writable bit
     */
    bool writable()
    {
        return BitArray(&data, 64)[1];
    }
    
    /**
     * Set the page writable bit
     */
    void writable(bool b)
    {
        BitArray(&data, 64)[1] = b;
    }
    
    /**
     * Get the page superuser bit
     */
    bool superuser()
    {
        return BitArray(&data, 64)[2];
    }
    
    /**
     * Set the superuser bit
     */
    void superuser(bool b)
    {
        BitArray(&data, 64)[2] = b;
    }
    
    /**
     * Get the page writethrough bit
     */
    bool writethrough()
    {
        return BitArray(&data, 64)[3];
    }
    
    /**
     * Set the page writethrough bit
     */
    void writethrough(bool b)
    {
        BitArray(&data, 64)[3] = b;
    }
    
    /**
     * Get the page cache disable bit
     */
    bool nocache()
    {
        return BitArray(&data, 64)[4];
    }
    
    /**
     * Set the page cache disable bit
     */
    void nocache(bool b)
    {
        BitArray(&data, 64)[4] = b;
    }
    
    /**
     * Get the page accessed bit
     */
    bool accessed()
    {
        return BitArray(&data, 64)[5];
    }
    
    /**
     * Set the page accessed bit
     */
    void accessed(bool b)
    {
        BitArray(&data, 64)[5] = b;
    }
    
    /**
     * Get the page dirty bit
     */
    bool dirty()
    {
        return BitArray(&data, 64)[6];
    }
    
    /**
     * Set the page dirty bit
     */
    void dirty(bool b)
    {
        BitArray(&data, 64)[6] = b;
    }
    
    /**
     * Get the pat bit
     */
    bool pat()
    {
        return BitArray(&data, 64)[7];
    }
    
    /**
     * Set the pat bit
     */
    void pat(bool b)
    {
        BitArray(&data, 64)[7] = b;
    }
    
    /**
     * Get the page global bit
     */
    bool global()
    {
        return BitArray(&data, 64)[8];
    }
    
    /**
     * Set the page global bit
     */
    void global(bool b)
    {
        BitArray(&data, 64)[8] = b;
    }
    
    /**
     * Get the page noexecute bit
     */
    bool noexecute()
    {
        return BitArray(&data, 64)[63];
    }
    
    /**
     * Set the page noexecute bit
     */
    void noexecute(bool b)
    {
        BitArray(&data, 64)[63] = b;
    }
    
    /**
     * Get the page physical address
     */
    ulong address()
    {
        return data & 0x0007FFFFFFFFF000;
    }
    
    /**
     * Set the page physical address
     */
    void address(ulong addr)
    {
        addr &= 0x0007FFFFFFFFF000;
        data &= 0xFFF8000000000FFF;
        data |= addr;
    }
    
    /**
     * Invalidate the TLB for the set address
     */
    public void invalidate()
    {
        asm
        {
            "invlpg (%[address])" : : [address] "a" address();
        }
    }
}

/**
 * Page table abstraction
 */
struct PageTable
{
    Page[512] table;
    
    /**
     * Compute the index into the given level page table
     *
     * Params:
     *  level = page table level
     *  address = virtual address
     *
	 * Returns: index into the given level's page table
	 *  for the given virtual address
	 */
    private size_t getIndex(size_t level, ulong address)
    {
        return (address >> (3 + level*9)) & 0x1FF;
    }
    
    /**
     * Get the page entry for the given address
     *
     * Params:
     *  address = virtual address to look up
     *
     * Returns: pointer to the page table entry
     */
    public Page* opIndex(vaddr_t address)
    {
        return opIndex(cast(size_t)address);
    }
    
    /**
     * Get the page entry for the given address
     *
     * Params:
     *  address = virtual address to look up
     *
     * Returns: pointer to the page table entry
     */
    public Page* opIndex(size_t address)
    {
        Page* t = table.ptr;
        size_t level = 4;
        
        while(level > 1)
        {
            size_t index = getIndex(level, address);

            if(!t[index].present)
            {
                t[index].writable = true;
                t[index].superuser = false;
                t[index].writethrough = false;
                t[index].nocache = false;
                t[index].accessed = false;
                t[index].dirty = false;
                t[index].pat = false;
                t[index].global = false;
                
                ulong a = System.memory.physical.getPage();
                
                memset(ptov(a), 0, 4096);
                
                t[index].address = a;
                
                t[index].noexecute = false;
                t[index].present = true;
            }
            
            t = cast(Page*)ptov(t[index].address);
            
            level--;
        }
        
        size_t index = getIndex(level, address);
        
        return &(t[index]);
    }
}
