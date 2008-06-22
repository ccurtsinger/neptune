/**
 * x86 paging support
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.paging;

import kernel.arch.i586.constants;
import kernel.arch.i586.registers;
import kernel.arch.i586.util;

import kernel.mem.range;

import std.bitarray;

struct Page
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

    void invalidate()
    {
        version(arch_i586)
        {
            asm
            {
                "invlpg (%[address])" : : [address] "a" base();
            }
        }
        else
        {
            assert(false, "Unsupported operation on non-native architecute: Page.invalidate()");
        }
    }

    // Define single bit access properties
    mixin(property!("present", "bool", "bits[0]"));
    mixin(property!("writable", "bool", "bits[1]"));
    mixin(property!("user", "bool", "bits[2]"));
    mixin(property!("writethrough", "bool", "bits[3]"));
    mixin(property!("cachedisable", "bool", "bits[4]"));
    mixin(property!("accessed", "bool", "bits[5]"));
    mixin(property!("dirty", "bool", "bits[6]"));
    mixin(property!("large", "bool", "bits[7]"));
    mixin(property!("global", "bool", "bits[8]"));
    
    // Define OS-used properties
    mixin(property!("used", "bool", "bits[9]"));
    mixin(property!("locked", "bool", "bits[10]"));

    // Define the base address property (shift left 22 bits when getting, right 22 when setting)
    mixin(property!("base", "size_t", "bits[22..32]", "<<22", ">>22"));
}

struct PageTable
{
    private Page[1024] pages;
    
    private Page* findPage(size_t address)
    {
        return &(pages[address>>22]);
    }
    
    public size_t load()
    {
        size_t old_pagetable = cr3;
        size_t physical = lookup(this);
        cr3 = physical;
        
        return old_pagetable;
    }
    
    public size_t lookup(void* address)
    {
        Page* p = findPage(cast(size_t)address);
        
        if(p.present)
            return p.base + cast(size_t)address % FRAME_SIZE;
        
        return 0;
    }
    
    public size_t reverseLookup(size_t address, bool writable = false, bool user = false)
    {
        size_t offset = address & ~0x400000;
        size_t base = address - offset;
        
        foreach(size_t i, p; pages)
        {
            if(p.present() && base == p.base() && (!writable || p.writable()) && (!user || p.user()))
            {
                return (i<<22) | offset;
            }
        }
        
        return 0;
    }
    
    public bool map(size_t v_addr, size_t p_addr, Permission user, Permission superuser, bool global, bool locked)
    {
        Page* p = findPage(v_addr);
        
        assert(p !is null, "Page not found");
        assert(p.used, "Cannot map unallocated page");
        
        bool writable = false;
        bool user_flag = false;
        
        if(user.r || user.w || user.x)
            user_flag = true;
            
        if(user.w)
            writable = true;
        
        // Check if the page is already mapped.  If the requested mapping is already present, return true
        if(p.present && p.base == p_addr && p.writable == writable && p.user == user_flag && p.global == global)
            return true;
            
        else if(p.present)
            return false;

        p.clear();
        p.base = p_addr;
        p.writable = writable;
        p.user = user_flag;
        p.global = global;
        p.large = true;
        p.present = true;
        p.locked = locked;
        p.used = true;
        
        p.invalidate();
        
        return true;
    }
    
    public bool unmap(size_t v_addr)
    {
        Page* p = findPage(v_addr);
        
        if(!p.present)
            return false;
        
        p.present = false;
        
        p.invalidate();
        
        return true;
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
        size_t found_base = 0;
        size_t found_count = 0;
        
        size_t offset = 0;
        
        while(found_count * FRAME_SIZE < size && offset <= bound.size - FRAME_SIZE)
        {
            Page* p;
            
            if(increasing)
                p = findPage(bound.base + offset);
            else
                p = findPage(bound.top - offset - FRAME_SIZE);
            
            if(!p.used)
            {
                if(found_count == 0 || !increasing)
                    found_base = offset;
                
                found_count++;
            }
            else
            {
                found_count = 0;
            }
         
            offset += FRAME_SIZE;
        }
        
        if(found_count * FRAME_SIZE >= size)
        {
            for(size_t i=0; i<found_count; i++)
            {
                Page* p;
                
                if(increasing)
                    p = findPage(bound.base + found_base + i*FRAME_SIZE);
                else
                    p = findPage(bound.top - found_base - FRAME_SIZE + i*FRAME_SIZE);
                
                p.used = true;
            }
            
            if(increasing)
                return MemoryRange(bound.base + found_base, found_count * FRAME_SIZE);
                
            else
                return MemoryRange(bound.top - found_base - FRAME_SIZE, found_count * FRAME_SIZE);
        }
        
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
        for(size_t c = 0; c <= range.size - FRAME_SIZE; c += FRAME_SIZE)
        {
            Page* p = findPage(c + range.base);
            p.used = false;
        }
    }
}
