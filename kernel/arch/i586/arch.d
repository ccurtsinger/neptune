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

import kernel.mem.range;

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

const size_t INT_DIVIDE_BY_ZERO = 0;
const size_t INT_DEBUG = 1;
const size_t INT_NMI = 2;
const size_t INT_BREAKPOINT = 3;
const size_t INT_OVERFLOW = 4;

const size_t INT_INVALID_OPCODE = 6;
const size_t INT_PAGE_FAULT = 14;

const size_t INT_ALIGNMENT_CHECK = 17;

const size_t INT_KEYBOARD = 33;
const size_t INT_COM2 = 35;
const size_t INT_COM1 = 36;
const size_t INT_LPT2 = 37;
const size_t INT_FLOPPY = 38;
const size_t INT_LPT1 = 39;
const size_t INT_RTC = 40;
const size_t INT_MOUSE = 44;
const size_t INT_IDE1 = 46;
const size_t INT_IDE2 = 47;

const size_t INT_TIMER = 80;

const size_t INT_SYSCALL_A = 128;
const size_t INT_SYSCALL_B = 129;
const size_t INT_SYSCALL_C = 130;

const size_t SEL_KERNEL_CODE = 0x8;
const size_t SEL_KERNEL_DATA = 0x10;
const size_t SEL_USER_CODE = 0x18;
const size_t SEL_USER_DATA = 0x20;
const size_t SEL_TSS = 0x28;

Descriptor[16] gdt;
Descriptor[256] idt;
TSS tss;

InterruptHandler[256] int_handlers;

PageTable* startup()
{
    disable_interrupts();

    PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);

    // null descriptor
    gdt[0].clear();

    // kernel code descriptor
    gdt[SEL_KERNEL_CODE/8].clear();
    gdt[SEL_KERNEL_CODE/8].user = true;
    gdt[SEL_KERNEL_CODE/8].code = true;
    gdt[SEL_KERNEL_CODE/8].present = true;
    gdt[SEL_KERNEL_CODE/8].readable = true;
    gdt[SEL_KERNEL_CODE/8].scaled = true;
    gdt[SEL_KERNEL_CODE/8].conforming = false;
    gdt[SEL_KERNEL_CODE/8].base = 0;
    gdt[SEL_KERNEL_CODE/8].limit = 0xFFFFF;
    gdt[SEL_KERNEL_CODE/8].dpl = 0;
    gdt[SEL_KERNEL_CODE/8].pmode = true;

    // kernel data descriptor
    gdt[SEL_KERNEL_DATA/8].clear();
    gdt[SEL_KERNEL_DATA/8].user = true;
    gdt[SEL_KERNEL_DATA/8].code = false;
    gdt[SEL_KERNEL_DATA/8].present = true;
    gdt[SEL_KERNEL_DATA/8].writable = true;
    gdt[SEL_KERNEL_DATA/8].scaled = true;
    gdt[SEL_KERNEL_DATA/8].base = 0;
    gdt[SEL_KERNEL_DATA/8].limit = 0xFFFFF;
    gdt[SEL_KERNEL_DATA/8].dpl = 0;
    gdt[SEL_KERNEL_DATA/8].pmode = true;

    // user code descriptor
    gdt[SEL_USER_CODE/8].clear();
    gdt[SEL_USER_CODE/8].user = true;
    gdt[SEL_USER_CODE/8].code = true;
    gdt[SEL_USER_CODE/8].present = true;
    gdt[SEL_USER_CODE/8].readable = true;
    gdt[SEL_USER_CODE/8].scaled = true;
    gdt[SEL_USER_CODE/8].conforming = false;
    gdt[SEL_USER_CODE/8].base = 0;
    gdt[SEL_USER_CODE/8].limit = 0xFFFFF;
    gdt[SEL_USER_CODE/8].dpl = 3;
    gdt[SEL_USER_CODE/8].pmode = true;

    // user data descriptor
    gdt[SEL_USER_DATA/8].clear();
    gdt[SEL_USER_DATA/8].user = true;
    gdt[SEL_USER_DATA/8].code = false;
    gdt[SEL_USER_DATA/8].present = true;
    gdt[SEL_USER_DATA/8].writable = true;
    gdt[SEL_USER_DATA/8].scaled = true;
    gdt[SEL_USER_DATA/8].base = 0;
    gdt[SEL_USER_DATA/8].limit = 0xFFFFF;
    gdt[SEL_USER_DATA/8].dpl = 3;
    gdt[SEL_USER_DATA/8].pmode = true;
    
    // TSS descriptor
    gdt[SEL_TSS/8].clear();
    gdt[SEL_TSS/8].base = cast(size_t)&tss;
    gdt[SEL_TSS/8].limit = TSS.sizeof;
    gdt[SEL_TSS/8].type = DescriptorType.TSS;
    gdt[SEL_TSS/8].present = true;
    gdt[SEL_TSS/8].dpl = 0;

    lgdt(gdt);
    
    // Set up interrupts
    for(int i=0; i<idt.length; i++)
    {
        idt[i].clear();
        idt[i].present = true;
        idt[i].dpl = 3;
        idt[i].user = false;
        idt[i].type = DescriptorType.INTERRUPT_GATE;
        idt[i].selector = SEL_KERNEL_CODE;
    }
    
    mixin(isr_ref!());
    
    int_handlers[0] = InterruptHandler("divide by zero exception");
    int_handlers[1] = InterruptHandler("debug exception");
    int_handlers[2] = InterruptHandler("non-maskable interrupt");
    int_handlers[3] = InterruptHandler("breakpoint exception");
    int_handlers[4] = InterruptHandler("overflow exception");
    int_handlers[5] = InterruptHandler("bound-range exception");
    int_handlers[6] = InterruptHandler("invalid opcode");
    int_handlers[7] = InterruptHandler("device not available");
    int_handlers[8] = InterruptHandler("double fault");
    int_handlers[10] = InterruptHandler("invalid TSS");
    int_handlers[11] = InterruptHandler("segment not present");
    int_handlers[12] = InterruptHandler("stack exception");
    int_handlers[13] = InterruptHandler("general protection fault");
    int_handlers[14] = InterruptHandler("page fault");
    int_handlers[16] = InterruptHandler("x87 floating point exception");
    int_handlers[17] = InterruptHandler("alignment check exception");
    int_handlers[18] = InterruptHandler("machine check exception");
    int_handlers[19] = InterruptHandler("SIMD floating point exception");
    
    lidt(idt);
    
    ltr(SEL_TSS);
    
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

void set_kernel_entry_stack(size_t p)
{
    tss.ss0 = SEL_KERNEL_DATA;
    tss.esp0 = p;
}

size_t get_kernel_entry_stack()
{
    return tss.esp0;
}

void load_page_table(size_t pagetable)
{
    cr3 = pagetable;
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

void set_interrupt_handler(int interrupt, bool function(Context*) handler)
{
    int_handlers[interrupt] = InterruptHandler(handler, "interrupt handler failed");
}

void clear_interrupt_handler(int interrupt)
{
    int_handlers[interrupt] = InterruptHandler("unhandled interrupt");
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

struct InterruptHandler
{
    bool set = false;
    char[] error = "unhandled interrupt";
    bool function(Context*) handler = null;
    
    public static InterruptHandler opCall(char[] error)
    {
        InterruptHandler i;
        i.error = error;
        return i;
    }
    
    public static InterruptHandler opCall(bool function(Context*) handler, char[] error)
    {
        InterruptHandler i;
        i.handler = handler;
        i.error = error;
        i.set = true;
        return i;
    }
    
    public bool opCall(Context* c)
    {
        assert(handler !is null, "Invoked null interrupt handler");
        
        return handler(c);
    }
}

extern(C) void common_interrupt(int interrupt, int error, Context* context)
{
    if(!int_handlers[interrupt].set || !int_handlers[interrupt](context))
    {
        writefln("interrupt %u: %s", interrupt, int_handlers[interrupt].error);
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
}
