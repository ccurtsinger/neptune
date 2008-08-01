/**
 * Process abstraction
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.task.process;

import std.context;
import std.activation;

import util.arch.arch;
import util.arch.paging;
import util.spec.elf64;

import kernel.core.env;

import kernel.mem.virtual;

import kernel.task.procallocator;

class Process
{
    size_t id;
    PageTable* pagetable;
    
    Activation* sa;
    
    VirtualAllocator stack;
    
    ulong entry;
    
    public this(size_t id, Elf64Header* elf)
    {
        this.id = id;
        
        stack = VirtualAllocator(0x400000, 0x800000, false);
        
        sa = null;
        
        pagetable = cast(PageTable*)ptov(p_alloc());

        pagetable.table[128..512] = cpu.pagetable.table[128..512];
        
        for(size_t i=0; i<128; i++)
        {
            pagetable.table[i] = Page();
        }

        elf.load(pagetable, true);
        
        entry = elf.entry;
        
        sa = procalloc.getActivation();
        
        procalloc.request(this);
    }
    
    public void upcall(Processor p, Context* dest)
    {
        assert(sa !is null, "Attempted to upcall to process on null activation");
        
        sa.processor_id = p.id;
        
        size_t stack_base = stack.allocate();
        size_t stack_top = stack_base + FRAME_SIZE;
        
        Page* stack_page = (*pagetable)[stack_base];
        stack_page.address = p_alloc();
        stack_page.writable = true;
        stack_page.present = true;
        stack_page.user = true;
        
        Context context;
        context.rip = entry;
        context.rbp = stack_top - 2 * ulong.sizeof;
        context.rsp = context.rbp - Activation.sizeof;
        context.rdi = context.rsp;
        context.rflags = 0x000000000000202;
        context.cs = 0x18 | 3;
        context.ss = 0x20 | 3;
        
        cpu.pagetable = pagetable;
        cpu.loadPageDir();
        
        *(cast(Activation*)context.rsp) = *sa;
        
        p.loadContext(sa.activation_id, dest, &context, this);
        
        delete sa;
        sa = null;
    }
}
