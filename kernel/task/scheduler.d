/**
 * Thread Scheduler
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module kernel.task.scheduler;

import arch.x86_64.cpu;

import std.queue;
import std.stdio;

import kernel.core.env;
import kernel.core.interrupt;
import kernel.task.process;
import kernel.task.thread;

class Scheduler
{
    Thread current;
    Queue!(Thread) threads;
    
    public this()
    {
        threads = new Queue!(Thread);
        
        current = null;
    }
    
    public void addThread(Thread t)
    {
        t.active = true;
        threads.add(t);
    }
    
    public Thread removeCurrent(InterruptStack* context)
    {
        current.context = *context;
        Thread t = current;
        
        current.running = false;
        
        current = null;
        
        return t;
    }
    
    public void taskSwitch(InterruptStack* context)
    {
        if(current !is null)
        {
            current.context = *context;
            current.running = false;
            threads.add(current);
        }
        
        current = threads.get();
        
        *context = current.context;
        
        cpu.pagetable = current.process.pagetable;
        cpu.loadPageDir();
        
        current.running = true;
    }
}
