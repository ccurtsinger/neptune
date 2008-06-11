/**
 * i586 (x86) Architecture Support
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.arch;

version(arch_i586):

import kernel.arch.i586.registers;
import kernel.arch.i586.structures;
import kernel.arch.i586.interrupts;
import kernel.arch.i586.pic;
import kernel.arch.i586.screen;

import std.stdio;

const size_t KERNEL_VIRTUAL_BASE = 0xC0000000;
const size_t USER_VIRTUAL_TOP = KERNEL_VIRTUAL_BASE;

const size_t STACK_TOP = 0xA0000000;
const size_t KERNEL_STACK_TOP = 0xE0000000;

const size_t PHYSICAL_MEMORY_MAX = 0xFFFFFFFF;
const size_t VIRTUAL_MEMORY_MAX = 0xFFFFFFFF;

const size_t FRAME_SIZE = 0x400000;
const size_t FRAME_BITS = 22;
const size_t HZ = 4;

const size_t INT_KEYBOARD = 33;
const size_t INT_MOUSE = 44;

Descriptor[16] gdt;
Descriptor[256] idt;

PageTable* startup()
{
    disable_interrupts();

    PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);

    // null descriptor
    gdt[0].clear();

    // kernel code descriptor
    gdt[1].clear();
    gdt[1].user = true;
    gdt[1].code = true;
    gdt[1].present = true;
    gdt[1].readable = true;
    gdt[1].scaled = true;
    gdt[1].conforming = false;
    gdt[1].base = 0;
    gdt[1].limit = 0xFFFFF;
    gdt[1].dpl = 0;
    gdt[1].pmode = true;

    // kernel data descriptor
    gdt[2].clear();
    gdt[2].user = true;
    gdt[2].code = false;
    gdt[2].present = true;
    gdt[2].writable = true;
    gdt[2].scaled = true;
    gdt[2].base = 0;
    gdt[2].limit = 0xFFFFF;
    gdt[2].dpl = 0;
    gdt[2].pmode = true;

    // user code descriptor
    gdt[3].clear();
    gdt[3].user = true;
    gdt[3].code = true;
    gdt[3].present = true;
    gdt[3].readable = true;
    gdt[3].scaled = true;
    gdt[3].conforming = false;
    gdt[3].base = 0;
    gdt[3].limit = 0xFFFFF;
    gdt[3].dpl = 3;
    gdt[3].pmode = true;

    // user data descriptor
    gdt[4].clear();
    gdt[4].user = true;
    gdt[4].code = false;
    gdt[4].present = true;
    gdt[4].writable = true;
    gdt[4].scaled = true;
    gdt[4].base = 0;
    gdt[4].limit = 0xFFFFF;
    gdt[4].dpl = 3;
    gdt[4].pmode = true;

    lgdt(gdt);

    // Set up the IDT
    
    for(int i=0; i<idt.length; i++)
    {
        idt[i].clear();
        idt[i].present = true;
        idt[i].dpl = 0;
        idt[i].user = false;
        idt[i].type = 0xE;
        idt[i].selector = 0x8;
    }
    
    mixin(isr_ref!());

    lidt(idt);
    
    remap_pic(32, 0xFFFF);

    enable_interrupts();
    
    screen_mem = cast(byte*)pagetable.reverseLookup(cast(void*)0xB8000);
    
    clear_screen();
    
    return pagetable;
}

size_t ptov(size_t p_addr)
{
    PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);
    
    size_t v = pagetable.reverseLookup(p_addr);
    
    assert(v != 0, "Physical page unavailable");
    
    return v;
}

void disable_interrupts()
{
    asm{"cli";}
}

void enable_interrupts()
{
    asm{"sti";}
}

void load_page_table(size_t pagetable)
{
    cr3 = pagetable;
}

struct MemoryRange
{
    public size_t base;
    public size_t size;
    
    public static MemoryRange opCall(size_t base, size_t size)
    {
        MemoryRange m;
        
        m.base = base;
        m.size = size;
        
        return m;
    }
    
    public size_t top()
    {
        return base + size;
    }
    
    public void top(size_t t)
    {
        assert(t >= base, "cannot define range with negative size");
        
        size = t - base;
    }
}

struct PageTable
{
    private Page[1024] pages;
    
    private Page* findPage(size_t address)
    {
        return &(pages[address>>22]);
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

    public void clear()
    {
        foreach(p; pages)
        {
            p.clear();
        }
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

struct Context
{
    uint eax;
    uint ebx;
    uint ecx;
    uint edx;
    uint esi;
    uint edi;
    uint ebp;
    uint eip;
    uint cs;
    uint flags;
    uint esp;
    uint ss;
}

const char[][] named_exceptions = [ "divide by zero exception",
                                    "debug exception",
                                    "non-maskable interrupt",
                                    "breakpoint exception",
                                    "overflow exception",
                                    "bound-range exception",
                                    "invalid opcode",
                                    "device not available",
                                    "double fault",
                                    "coprocessor segment overrun",
                                    "invalid TSS",
                                    "segment not present",
                                    "stack exception",
                                    "general protection fault",
                                    "page fault",
                                    "reserved exception",
                                    "x87 floating point exception",
                                    "alignment check exception",
                                    "machine check exception",
                                    "SIMD floating point exception"];

extern(C) void common_interrupt(int interrupt, int error, Context* context)
{
    if(interrupt < named_exceptions.length)
    {
        writeln(named_exceptions[interrupt]);
    }
    else
    {
        writefln("interrupt %u", interrupt);
    }
    
    writefln("  error: %02#x", error);
    writefln("   %%eip: %08#x", context.eip);
    writefln("   %%esp: %08#x", context.esp);
    writefln("   %%ebp: %08#x", context.ebp);
    writefln("    %%cs: %02#x", context.cs);
    writefln("    %%ss: %02#x", context.ss);
    writefln("   %%eax: %08#x", context.eax);
    writefln("   %%ebx: %08#x", context.ebx);
    writefln("   %%ecx: %08#x", context.ecx);
    writefln("   %%edx: %08#x", context.edx);
    writefln("   %%esi: %08#x", context.esi);
    writefln("   %%edi: %08#x", context.edi);
    writefln("   %%cr2: %08#x", cr2);
    writefln("  flags: %08#x", context.flags);
    
    for(;;){}
}
