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
import kernel.mem.physical;

import std.mem;
import std.bitarray;

debug import std.stdio;

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
        return data & ~0xFFF;
    }
    
    void base(size_t b)
    {
        data &= 0x00000FFF;
        data |= b & ~0xFFF;
    }
}

struct PageTable
{
    private PageTableEntry[1024] entries;
    
    private PageTableEntry* findPage(size_t address, bool recursing = false)
    {
        size_t dir_index = address>>22;
        size_t table_index = (address>>12) & 0x3FF;
        
        PageTableEntry* dir_entry = &(entries[dir_index]);
        PageTableEntry* table_entry;
        
        PageTableEntry[] table;
        
        bool kernel_mem;
        
        if(dir_index < KERNEL_VIRTUAL_BASE>>22)
        {
            table = (cast(PageTableEntry*)(USER_MEM_DIR + dir_index*FRAME_SIZE))[0..1024];
            kernel_mem = false;
        }
        else
        {
            table = (cast(PageTableEntry*)(KERNEL_MEM_DIR + dir_index*FRAME_SIZE))[0..1024];
            kernel_mem = true;
        }
        
        if(!dir_entry.present)
        {
            assert(!recursing, "Endless recursive loop in PageTable.findPage()");
            
            size_t new_table = p_alloc();
        
            dir_entry.clear();
            dir_entry.base = new_table;
            dir_entry.writable = true;
            dir_entry.user = true;
            dir_entry.present = true;
            
            PageTableEntry* table_ref = findPage(cast(size_t)table.ptr, true);
            
            table_ref.clear();
            table_ref.base = new_table;
            table_ref.writable = true;
            table_ref.user = false;
            table_ref.present = true;
            
            invalidate(cast(size_t)table.ptr);
            
            memset(table.ptr, 0, FRAME_SIZE);
        }
        
        return &(table[table_index]);
    }
    
    public PageTable* clone()
    {
        MemoryRange r = allocate(FRAME_SIZE, MemoryRange(KERNEL_STACK_TOP, KERNEL_MEM_DIR - KERNEL_STACK_TOP));
        size_t new_pagetable = p_alloc();
        map(r.base, new_pagetable, Permission("---"), Permission("rw-"), true, true);
    
        PageTable* p = cast(PageTable*)r.base;
        
        for(size_t i=0; i<1024; i++)
        {
            p.entries[i].clear();
            
            if(i >= KERNEL_VIRTUAL_BASE>>22)
            {
                //make sure all page tables are mapped into the top level directory before cloning
                findPage(i<<22);
                p.entries[i] = entries[i];
            }
        }
        
        size_t new_table = p_alloc();
        
        PageTableEntry* user_dir = &(p.entries[USER_MEM_DIR>>22]);
        user_dir.base = new_table;
        user_dir.writable = true;
        user_dir.user = false;
        user_dir.present = true;
        
        MemoryRange temp_mem = allocate(FRAME_SIZE, MemoryRange(KERNEL_STACK_TOP, KERNEL_MEM_DIR - KERNEL_STACK_TOP));
        
        map(temp_mem.base, new_table, Permission("---"), Permission("rw-"), false, false);
        
        PageTableEntry[] table = (cast(PageTableEntry*)temp_mem.base)[0..1024];
        
        PageTableEntry* user_dir_ref = &(table[USER_MEM_DIR>>22]);
        
        user_dir_ref.base = new_table;
        user_dir_ref.writable = true;
        user_dir_ref.user = false;
        user_dir_ref.present = true;
        
        //unmap(r.base);
        //unmap(temp_mem.base);
        
        free(temp_mem);
        
        return p;
    }
    
    void invalidate(size_t address)
    {
        version(arch_i586)
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
        PageTableEntry* p = findPage(cast(size_t)address);
        
        if(p.present)
            return p.base + cast(size_t)address % FRAME_SIZE;
        
        return 0;
    }
    
    public bool map(size_t v_addr, size_t p_addr, Permission user, Permission superuser, bool global, bool locked)
    {
        debug writefln("mapping %p to %p", v_addr, p_addr);
        
        PageTableEntry* p = findPage(v_addr);
        
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
        {
            debug writefln("existing entry used: %p", p.data);
            return true;
        }
        else if(p.present)
        {
            debug writefln("existing entry conflicts: %p", p.data);
            return false;
        }
        
        p.clear();
        p.base = p_addr;
        p.writable = writable;
        p.user = user_flag;
        p.global = global;
        p.present = true;
        p.locked = locked;
        p.used = true;
        
        invalidate(v_addr);
        
        debug writefln("new entry set: %p", p.data);
        
        return true;
    }
    
    public bool unmap(size_t v_addr)
    {
        PageTableEntry* p = findPage(v_addr);
        
        if(!p.present)
            return false;
        
        p.present = false;
        
        invalidate(v_addr);
        
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
            PageTableEntry* p;
            
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
                PageTableEntry* p;
                
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
            PageTableEntry* p = findPage(c + range.base);
            p.used = false;
        }
    }
}
