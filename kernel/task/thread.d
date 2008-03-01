/**
 * Thread abstraction
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module kernel.task.thread;

import arch.x86_64.arch;

import kernel.core.env;

import kernel.task.process;

class Thread
{
    Process process;
    InterruptStack context;
    
    ulong threadStack;
    ulong kernelStack;
    
    bool active;
    bool running;
    bool ready;
    
    public this(Process process, ulong entry, ushort cs, ushort ss, ulong threadStack, ulong kernelStack)
    {
        this.process = process;
        this.threadStack = threadStack;
        this.kernelStack = kernelStack;
        
        context.rip = entry;
        context.rbp = threadStack;
        context.rsp = threadStack;
        context.cs = cs;
        context.ss = ss;
        context.rflags = 0x000000000000202;
        
        active = false;
        running = false;
        ready = true;
    }
}
