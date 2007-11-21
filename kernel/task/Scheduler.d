
module kernel.task.Scheduler;

import std.collection.queue;
import std.task.Scheduler;
import std.task.Thread;

import neptune.arch.idt;

import kernel.task.Thread;

class CooperativeScheduler : Scheduler
{
    private Queue!(KernelThread) queue;
    private KernelThread current;
    private ulong nextID;
    
    public this(KernelThread current, IDT* idt)
    {
        this.current = current;
        queue = new Queue!(KernelThread);
        
        nextID = current.getID()+1;
        
        idt.setHandler(255, &this.task_switcher);
        idt.setHandler(254, &this.create_thread);
        idt.setHandler(253, &this.task_switcher);
    }
    
    public void addThread(Thread t)
    {
        if(cast(KernelThread)t !is null)
            queue.enqueue(cast(KernelThread)t);
    }
    
    public ulong addThread(void function() thread)
    {
        ulong result;
        
        void* stack = System.memory.stack.allocate();
    
        asm
        {
            "int $254" : "=a" result, "=c" thread : "b" stack, "c" thread;
        }
        
        if(result == 0)
        {
            thread();
            assert(false, "Unhandled thread termination");
        }
        
        return result;
    }
    
    public Thread thread()
    {
        return current;
    }
    
    public void yield()
    {
        asm
        {
            "int $255";
        }
    }
    
    public void exit()
    {
        asm
        {
            "int $253";
        }
    }
    
    void create_thread(ulong interrupt, ulong error, InterruptStack* context)
    {
        ulong stack;
        
        asm
        {
            "mov %%rbx, %[stack]" : [stack] "=Nd" stack;
        }
        
        // Create a new thread with the stack pointer specified in rbx
        KernelThread t = new KernelThread(nextID, stack);
        
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
        if(interrupt == 255)
        {
            current.setContext(*context);
        
            queue.enqueue(current);
        }
        else
        {
            delete current;
        }
        
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
