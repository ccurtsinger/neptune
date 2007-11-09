
module kernel.task.Scheduler;

import std.collection.queue;

import neptune.arch.idt;

import kernel.task.Thread;

class Scheduler
{
    Queue!(Thread) queue;
    Thread current;
    
    ulong nextID;
    
    this(Thread current)
    {
        this.current = current;
        queue = new Queue!(Thread);
        
        nextID = current.getID()+1;
    }
    
    void addThread(Thread t)
    {
        queue.enqueue(t);
    }
    
    ulong getThreadID()
    {
        return current.getID();
    }
    
    void create_thread(ulong interrupt, ulong error, InterruptStack* context)
    {
        ulong stack;
        
        asm
        {
            "mov %%rbx, %[stack]" : [stack] "=Nd" stack;
        }
        
        // Create a new thread with the stack pointer specified in rbx
        Thread t = new Thread(nextID, stack);
        
        // Copy the current thread context
        InterruptStack newContext = *context;
        
        newContext.rax = 0;
        newContext.rsp = stack;
        
        t.setContext(newContext);
        addThread(t);
        
        context.rax = nextID;
        
        nextID++;
    }
    
    void task_switcher(ulong interrupt, ulong error, InterruptStack* context)
    {
        current.setContext(*context);
        
        queue.enqueue(current);
        
        current = queue.dequeue();
        
        InterruptStack* c = current.getContext();
        
        context.rax = c.rax;
        context.rbx = c.rbx;
        context.rcx = c.rcx;
        context.rdx = c.rdx;
        context.rsi = c.rsi;
        context.rdi = c.rdi;
        context.r8 = c.r8;
        context.r9 = c.r9;
        context.r10 = c.r10;
        context.r11 = c.r11;
        context.r12 = c.r12;
        context.r13 = c.r13;
        context.r14 = c.r14;
        context.r15 = c.r15;
        context.rbp = c.rbp;
        context.error = c.error;
        context.rip = c.rip ;
        context.cs = c.cs;
        context.rflags = c.rflags;
        context.rsp = c.rsp;
        context.ss = c.ss;
    }
}
