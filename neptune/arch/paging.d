/**
 * Paging Abstraction and Utilities
 *
 * Authors: Charlie Curtsinger
 * Date: October 28th, 2007
 * Version: 0.1a
 */

module neptune.arch.paging;

const ubyte PAGEDIR_L4 = 39;
const ubyte PAGEDIR_L3 = 30;
const ubyte PAGEDIR_L2 = 21;
const ubyte PAGEDIR_L1 = 12;

const ulong PAGEDIR_ADDR_MASK = 0xFFFFFFFFFFFFF000;
const ulong PAGEDIR_ENTRY_MASK = 0xFFFFFFFFFFFFF000;

const ulong PAGE_PRESENT = 0x1;
const ulong PAGE_READWRITE = 0x2;
const ulong PAGE_USER = 0x4;
const ulong PAGE_WRITETHROUGH = 0x8;
const ulong PAGE_CACHE_DISABLE = 0x10;
const ulong PAGE_ACCESSED = 0x20;
const ulong PAGE_DIRTY = 0x40;
const ulong PAGE_GLOBAL = 0x100;
const ulong PAGE_COPY_ON_WRITE = 0x200;
const ulong PAGE_NX = 0x8000000000000000;

import std.kernel;

/**
 * Abstraction for page directories and tables
 */
struct PageTable
{
	/// Pointer to array of page entries
    ulong* entries;
    
    /// Mask that leaves only bits that act as an index into entries
    ulong mask;
    
    /// Lowest bit index of mask - used to shift down and determine index into entries
    ubyte lowBit;

	/**
	 * Construct a PageTable object from an existing entries array
	 *
	 * Params:
	 *  lowBit = Lowest bit used to determine the index into entries
	 *  entries = Physical address of a set of page table entrires
	 *
	 * Returns: Newly created page table object
	 */
    public static PageTable opCall(ulong lowBit, ulong entries)
    {
    	PageTable p;
    	
        p.lowBit = lowBit;
        p.entries = cast(ulong*)ptov(entries);

        p.mask = (cast(ulong)0x1FF)<<lowBit;
        
        return p;
    }

	/**
	 * Construct a PageTable object and a new set of entries
	 *
	 * Params:
	 *  lowBit = Lowest bit used to determine the index into entries
	 *
	 * Returns: Newly created page table
	 */
    public static PageTable opCall(ulong lowBit)
    {
    	PageTable p;
    	
        p.lowBit = lowBit;
        p.entries = cast(ulong*)ptov(get_physical_page());

        p.mask = (cast(ulong)0x1FF)<<lowBit;

        for(int i=0; i<FRAME_SIZE/ulong.sizeof; i++)
        {
            p.entries[i] = 0;
        }
        
        return p;
    }

	/**
	 * Check if the present bit is set for a given entry
	 *
	 * Params:
	 *  entry = Contents of the entry
	 *
	 * Returns: true if the present bit is set
	 */
    private bool present(ulong entry)
    {
        return (entry & 0x1) == 1;
    }

	/**
	 * Invalidate a TLB entry
	 *
	 * Params:
	 *  vAddr = Virtual address to invalidate
	 *
	 */
    private void invalidate(ulong vAddr)
    {
        asm
        {
            "invlpg (%[addr])" : : [addr] "a" vAddr;
        }
    }

	/**
	 * Map a page or sequence of virtual pages into the page heirarchy
	 * 
	 * Params:
	 *  vAddr = Virtual address to map page(s) at
	 *  size = Size of the region to match - must be a multiple of FRAME_SIZE
	 *  flags = Flags to set for newly mapped page(s)
	 * 
	 * Returns: True if all pages mapped successfully
	 */
    public bool map(ulong vAddr, ulong size = FRAME_SIZE, ulong flags = PAGE_PRESENT | PAGE_READWRITE)
    {
        ulong index = (vAddr & mask) >> lowBit;
        ulong topIndex = ((vAddr+size-1) & mask) >> lowBit;

        int conflicts = 0;

        //If we're not in the page table level (L1)
        if(lowBit > PAGEDIR_L1)
        {
            while(index <= topIndex)
            {
                //Page directory is present
                if(present(entries[index]))
                {
                    //Instantiate a lower page directory with data at the entry address
                    PageTable nextLevel = PageTable(lowBit-9, entries[index] & PAGEDIR_ADDR_MASK);

                    //Map into the lower directory
                    conflicts -= nextLevel.map(vAddr, size, flags);
                }
                //Page directory doesn't exist yet
                else
                {
                    //Create a new page directory of lower order
                    PageTable nextLevel = PageTable(lowBit-9);

                    //Put an entry in the current directory
                    entries[index] = (vtop(nextLevel.entries) & PAGEDIR_ENTRY_MASK) | flags;

                    //Map into the lower directory
                    conflicts -= nextLevel.map(vAddr, size, flags);
                }

                index++;
            }
        }

        //We're at the page table level
        else
        {
            while(index <= topIndex)
            {
                //Make sure an entry doesn't already exist at this virtual address
                if(!present(entries[index]))
                {
                    entries[index] = (get_physical_page() & PAGEDIR_ENTRY_MASK) | flags;
                    invalidate(vAddr);
                }
                else
                {
                    conflicts++;
                }

                index++;
                vAddr += FRAME_SIZE;
            }
        }

        return conflicts == 0;
    }
}
