/**
 * Page table and entry abstractions
 *
 * Copyright: 2008 The Neptune Project
 */

module util.arch.paging;

import util.arch.arch;

import std.bitarray;
import std.integer;
import std.mem;

/**
 * Page table entry abstraction
 */
struct Page
{
    union
    {
        ulong data;
        BitArray bits;
    }

    /**
     * Initialize page data
     */
    static Page opCall()
    {
        Page p;
        p.present = false;
        return p;
    }
    
    void clear()
    {
        data = 0;
    }

    /**
     * Get the page present bit state
     */
    bool present()
    {
        return bits[0];
    }

    /**
     * Set the page present bit state
     */
    void present(bool b)
    {
        bits[0] = b;
    }

    /**
     * Get the page writable bit
     */
    bool writable()
    {
        return bits[1];
    }

    /**
     * Set the page writable bit
     */
    void writable(bool b)
    {
        bits[1] = b;
    }

    /**
     * Get the page superuser bit
     */
    bool user()
    {
        return bits[2];
    }

    /**
     * Set the superuser bit
     */
    void user(bool b)
    {
        bits[2] = b;
    }

    /**
     * Get the page writethrough bit
     */
    bool writethrough()
    {
        return bits[3];
    }

    /**
     * Set the page writethrough bit
     */
    void writethrough(bool b)
    {
        bits[3] = b;
    }

    /**
     * Get the page cache disable bit
     */
    bool nocache()
    {
        return bits[4];
    }

    /**
     * Set the page cache disable bit
     */
    void nocache(bool b)
    {
        bits[4] = b;
    }

    /**
     * Get the page accessed bit
     */
    bool accessed()
    {
        return bits[5];
    }

    /**
     * Set the page accessed bit
     */
    void accessed(bool b)
    {
        bits[5] = b;
    }

    /**
     * Get the page dirty bit
     */
    bool dirty()
    {
        return bits[6];
    }

    /**
     * Set the page dirty bit
     */
    void dirty(bool b)
    {
        bits[6] = b;
    }

    /**
     * Get the pat bit
     */
    bool pat()
    {
        return bits[7];
    }

    /**
     * Set the pat bit
     */
    void pat(bool b)
    {
        bits[7] = b;
    }

    /**
     * Get the page global bit
     */
    bool global()
    {
        return bits[8];
    }

    /**
     * Set the page global bit
     */
    void global(bool b)
    {
        bits[8] = b;
    }

    /**
     * Get the page noexecute bit
     */
    bool noexecute()
    {
        return bits[63];
    }

    /**
     * Set the page noexecute bit
     */
    void noexecute(bool b)
    {
        bits[63] = b;
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
        version(x86_64)
        {
            asm
            {
                "invlpg (%[address])" : : [address] "a" address();
            }
        }
        else
        {
            assert(false, "Cannot invalidate x86_64 pages in non-x86_64 architecture");
        }
    }
}

/**
 * Page table abstraction
 */
struct PageTable
{
    Page[512] table;

    public void init()
    {
        memset(table.ptr, 0, FRAME_SIZE);
    }

    /**
     * Get the page entry for the given address
     *
     * Params:
     *  address = virtual address to look up
     *
     * Returns: pointer to the page table entry
     */
    public Page* opIndex(ulong address)
    {
        Page[] dir = opIndex(address, 1);
        
        size_t index = getIndex(1, address);
        
        return &(dir[index]);
    }
    
    public Page[] opIndex(ulong address, size_t l)
    {
        size_t level = 4;
        
        Page* t = table.ptr;
        
        while(level > l)
        {
            size_t index = getIndex(level, address);
            
            if(!t[index].present)
            {
                t[index].clear();

                ulong a = p_alloc();

                memset(ptov(a), 0, FRAME_SIZE);

                t[index].address = a;
                t[index].writable = true;
                t[index].present = true;
                t[index].user = true;
            }
            
            t = cast(Page*)ptov(t[index].address);

            level--;
        }
        
        return t[0..512];
    }
}

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
public size_t getIndex(size_t level, ulong address)
{
    return (address >> (3 + level*9)) & 0x1FF;
}
