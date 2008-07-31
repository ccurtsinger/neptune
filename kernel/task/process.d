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

import kernel.task.procallocator;

class Process
{
    size_t id;
    PageTable* pagetable;
    
    Activation* sa;
    
    ulong entry;
    
    public this(size_t id, Elf64Header* elf)
    {
        this.id = id;
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
        assert(false, "Upcall");
        
        assert(sa !is null, "Attempted to upcall to process on null activation");
        
        sa.processor_id = p.id;
        
        Context context;
        context.rip = entry;
        //context.rbp = cast(ulong)heap.allocate(2*FRAME_SIZE) + 2*FRAME_SIZE - 2 * ulong.sizeof;
        context.rsp = context.rbp - Activation.sizeof;
        context.rdi = context.rsp;
        context.rsi = cast(ulong)&test_syscall;
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
