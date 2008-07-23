/**
 * x86 paging support
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.x86_64.paging;

import kernel.arch.x86_64.constants;
import kernel.arch.x86_64.registers;

import kernel.arch.util;

import kernel.mem.range;
import kernel.mem.physical;

import std.mem;
import std.bitarray;

struct PageTableEntry
{
    union
    {
        uint data;
        BitArray bits;
    }

    void clear()
    {
        data = 0;
    }

    // Define single bit access properties
    mixin(property!("present", "bool", "bits[0]"));
    mixin(property!("writable", "bool", "bits[1]"));
    mixin(property!("user", "bool", "bits[2]"));
    mixin(property!("writethrough", "bool", "bits[3]"));
    mixin(property!("cachedisable", "bool", "bits[4]"));
    mixin(property!("accessed", "bool", "bits[5]"));
    mixin(property!("dirty", "bool", "bits[6]"));
    //mixin(property!("large", "bool", "bits[7]"));
    mixin(property!("global", "bool", "bits[8]"));
    
    // Define OS-used properties
    mixin(property!("used", "bool", "bits[9]"));
    mixin(property!("locked", "bool", "bits[10]"));
    
    // Define the physical base address property
    //mixin(property!("base", "size_t", "bits[12..32]", "<<12", ">>12"));
    
    size_t base()
    {
        return data & 0xFFFFF000;
    }
    
    void base(size_t b)
    {
        data &= 0x00000FFF;
        data |= b & 0xFFFFF000;
    }
}

struct PageTable
{
    private PageTableEntry[1024] entries;
    
    private PageTableEntry* findPage(size_t address, bool recursing = false)
    {
        return null;
    }
    
    public PageTable* clone()
    {
        return null;
    }
    
    void invalidate(size_t address)
    {
        version(arch_x86_64)
        {
            asm
            {
                "invlpg (%[address])" : : [address] "a" address;
            }
        }
        else
        {
            assert(false, "Unsupported operation on non-native architecute: PageTableEntry.invalidate()");
        }
    }
    
    public size_t lookup(void* address)
    {
        return 0;
    }
    
    public bool map(size_t v_addr, size_t p_addr, Permission user, Permission superuser, bool global, bool locked)
    {
        return false;
    }
    
    public bool unmap(size_t v_addr)
    {
        return false;
    }
    
    /**
     * Allocate consecutive virtual pages of size 'size' or larger.
     *
     * Allocation will only be made in the given range.
     */
    public MemoryRange allocate(size_t size, MemoryRange bound, bool increasing = true)
    in
    {
        assert(bound.base % FRAME_SIZE == 0, "lower bound for virtual page allocation must be a multiple of FRAME_SIZE");
        assert(bound.size % FRAME_SIZE == 0, "size for virtual page allocation must be a multiple of FRAME_SIZE");
    }
    body
    {
        return MemoryRange(0, 0);
    }
    
    public void free(MemoryRange range)
    in
    {
        assert(range.base % FRAME_SIZE == 0, "lower bound for virtual page freeing must be a multiple of FRAME_SIZE");
        assert(range.size % FRAME_SIZE == 0, "size for virtual page freeing must be a multiple of FRAME_SIZE");
    }
    body
    {
        
    }
}
