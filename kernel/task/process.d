/**
 * Process abstraction
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module kernel.task.process;

import arch.x86_64.arch;
import arch.x86_64.paging;

import spec.elf64;

import kernel.core.env;

import kernel.task.scheduler;
import kernel.task.thread;
import kernel.mem.watermark;

class Process
{
    PageTable* pagetable;
    WatermarkAllocator heap;
    Thread[] threads;
    
    public this(Elf64Header* elf)
    {
        pagetable = cast(PageTable*)ptov(_d_palloc());
        
        pagetable.table[128..512] = cpu.pagetable.table[128..512];
        
        for(size_t i=0; i<128; i++)
        {
            pagetable.table[i] = Page();
        }
        
        heap.init(pagetable, 0x10000000);
        
        ulong threadStack = cast(ulong)heap.get(4*FRAME_SIZE) + 4*FRAME_SIZE - 2*ulong.sizeof;
        ulong kernelStack = cast(ulong)heap.get(4*FRAME_SIZE) + 4*FRAME_SIZE - 2*ulong.sizeof;
        
        threads ~= new Thread(this, elf.entry, 0x18 | 3, 0x20 | 3, threadStack, kernelStack);
        
        elf.load(pagetable, true);
    }
    
    public void start()
    {
        foreach(t; threads)
        {
            if(!t.active)
                scheduler.addThread(t);
        }
    }
}
