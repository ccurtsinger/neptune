/**
 * Paging Abstraction and Utilities
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
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

import std.stdlib;
import std.mem;

/**
 * Virtual memory class for page table management
 */
struct VirtualMemory
{
    /// Pointer to the top level page table's first entry
    PageEntry* pagetable;
    
    /**
     * Create a new VirtualMemory region from an existing top-level page table
     *
     * Params:
     *  p = physical address of the top-level page table
     */
    void init(ulong p)
    {
        pagetable = cast(PageEntry*)ptov(p);
    }
    
    /**
     * Default allocator for the class
     *
     * This must be defined because the default allocator is
     * overridden by the in-place allocator below.
     *
     * Params:
     *  size = size of the class to allocate
     *
     * Returns: pointer to the allocated memory
     */
    /*new(size_t size)
    {
        void* p = malloc(size);
        
        return p;
    }*/
    
    /**
     * In-place allocator for the class
     *
     * This is used before the virtual memory system has been set up
     *
     * Params:
     *  size = size of the class to allocate
     *  p = pointer to use as the base of the new class
     *
     * Returns: the passed in pointer, triggering an in-place allocation
     */
    /*new(size_t size, void* p)
    {
        return p;
    }*/
    
    /**
     * Map a page into this virtual address space
     *
     * Params:
     *  p = base pointer to the region to map
     *  flags = flags for the mapping
     */
    public bool map(void* p, ulong flags = PAGE_READWRITE)
    {
        // Create an integer representation of the pointer
        ulong vAddr = cast(ulong)p;
        
        // Set the page as present by default
        flags |= PAGE_PRESENT;
        
        PageEntry* table = pagetable;
        
        // Iterate through all four levels of the page heirarchy
        for(size_t level = 4; level > 0; level--)
        {
            // Gives low bits for page levels 4 to 1: 39, 30, 21, and 12
            size_t lowbit = 3 + level*9;
            
            // Compute indices into the current page directory level
            size_t index = (vAddr >> lowbit) & 0x1FFL;

            if(level > 1)
            {
                if(!table[index].present())
                {
                    ulong newtable = get_physical_page();
                    
                    memset(ptov(newtable), 0, FRAME_SIZE);
                    
                    table[index].setEntry(newtable, flags);
                }
                
                table = cast(PageEntry*)ptov(table[index].getEntryAddress());
            }
            else
            {
                if(!table[index].present())
                {
                    ulong newpage = get_physical_page();
                    
                    table[index].setEntry(newpage, flags);
                    
                    invalidate(vAddr);
                    
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * Invalidate the TLB entry for a virtual address
     *
     * Params:
     *  vAddr = address to invalidate
     */
    private void invalidate(ulong vAddr)
    {
        asm
        {
            "invlpg (%[addr])" : : [addr] "a" vAddr;
        }
    }
    
    /**
     * Structure representation of an entry into a page directory or table
     */
    struct PageEntry
    {
        ulong data;
        
        /**
         * Set the contents of this entry
         *
         * Params:
         *  p = physical address of the page table or page this entry should point to
         *  flags = flags for the entry
         */
        void setEntry(ulong p, ulong flags)
        {
            data = (p & PAGEDIR_ENTRY_MASK) | flags;
        }
        
        /**
         * Set the flags for this entry
         *
         * Params:
         *  flags = flags for the entry
         */
        void setEntryFlags(ulong flags)
        {
            setEntry(getEntryAddress(), flags);
        }
        
        /**
         * Get the physical address pointed to by this entry
         *
         * Returns: physical address of the entry's subtable or page
         */
        ulong getEntryAddress()
        {
            return data & PAGEDIR_ADDR_MASK;
        }
        
        /**
         * Check if this entry is marked as present
         */
        bool present()
        {
            return (data & 0x1) == 1;
        }
    }
}
