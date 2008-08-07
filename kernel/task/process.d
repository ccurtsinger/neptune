/**
 * Process abstraction
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.task.process;

import std.context;
import std.activation;

import util.arch.cpu;
import util.arch.paging;
import util.spec.elf64;

import kernel.core.env;
import kernel.mem.virtual;
import kernel.task.scheduler;

import std.stdio;

class Process
{
    size_t id;
    PageTable* pagetable;
    
    Thread thread;
    
    VirtualAllocator stack_mem;
    
    public this(size_t id, Elf64Header* elf)
    {
        this.id = id;
        
        stack_mem = VirtualAllocator(USER_STACK, false);
        
        pagetable = CPU.pagetable.clone();
        
        for(size_t i=0; i<128; i++)
        {
            pagetable.table[i] = Page();
        }

        elf.load(pagetable, true);
        
        thread = new Thread(elf.entry, stack_mem.allocate(), kernel_stack_mem.allocate());
    }
    
    public void run(Context* current)
    {
        CPU.pagetable = pagetable;
        
        thread.run(current);
    }
    
    public void save(Context* current)
    {
        thread.save(current);
    }
}

class Thread
{
    private Context context;
    
    public Range stack;
    public Range kernel_stack;
    
    public this(size_t entry, Range stack, Range kernel_stack)
    {
        this.stack = stack;
        this.kernel_stack = kernel_stack;
        
        context.rip = entry;
        context.rbp = stack.top - 2 * ulong.sizeof;
        context.rsp = context.rbp;
        context.rflags = 0x000000000000202;
        context.cs = 0x18 | 3;
        context.ss = 0x20 | 3;
    }
    
    public void run(Context* current)
    {
        CPU.tss.rsp0 = kernel_stack.top - 2 * ulong.sizeof;
        
        *current = context;
    }
    
    public void save(Context* current)
    {
        context = *current;
    }
}
