/**
 * Process abstraction
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.task.process;

import std.context;
import std.activation;

import util.arch.cpu;
import util.arch.arch;
import util.arch.paging;
import util.spec.elf64;

import kernel.core.env;

import kernel.mem.virtual;

import kernel.task.scheduler;

class Process
{
    size_t id;
    PageTable* pagetable;
    Context context;
    
    VirtualAllocator stack;
    
    public this(size_t id, Elf64Header* elf)
    {
        this.id = id;
        
        stack = VirtualAllocator(0x400000, 0x800000, false);;
        
        pagetable = cast(PageTable*)ptov(p_alloc());

        pagetable.table[128..512] = CPU.pagetable.table[128..512];
        
        for(size_t i=0; i<128; i++)
        {
            pagetable.table[i] = Page();
        }

        elf.load(pagetable, true);
        
        size_t stack_base = stack.allocate();
        size_t stack_top = stack_base + FRAME_SIZE;
        
        Page* stack_page = (*pagetable)[stack_base];
        stack_page.address = p_alloc();
        stack_page.writable = true;
        stack_page.present = true;
        stack_page.user = true;
        
        context.rip = elf.entry;
        context.rbp = stack_top - 2 * ulong.sizeof;
        context.rsp = context.rbp;
        context.rdi = context.rsp;
        context.rflags = 0x000000000000202;
        context.cs = 0x18 | 3;
        context.ss = 0x20 | 3;
    }
    
    public void run(Context* current)
    {
        CPU.pagetable = pagetable;
        
        *current = context;
    }
    
    public void save(Context* current)
    {
        context = *current;
    }
}
