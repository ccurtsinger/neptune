
module kernel.task.Scheduler;

import std.collection.Queue;
import std.task.Scheduler;
import std.task.Thread;
import std.port;

import kernel.arch.IDT;
import kernel.task.Thread;
import kernel.event.Interrupt;

class BasicScheduler : Scheduler
{
    private Queue!(Thread) queue;
    private Thread currentThread;
    
    public this()
    {
        currentThread = null;
        
        queue = new Queue!(Thread);
        
        setHandler(255, &task_switcher);
        setHandler(32, &timer_int);
    }
    
    public Thread current()
    {
        return currentThread;
    }
    
    public synchronized void addThread(Thread t)
    {
        queue.enqueue(t);
    }
    
    public synchronized void removeThread(Thread t)
    {
        assert(false, "Thread removal is not yet implemented");
    }
    
    public void taskSwitch(ThreadState s = ThreadState.Ready)
    {
        asm
        {
            "int $255" : : "a" s;
        }
    }
    
    public bool timer_int(InterruptStack* context)
    {
        // Save rax and set to ready state
        size_t rax = context.rax;
        context.rax = ThreadState.Ready;
        
        // Perform context switch
        task_switcher(context);
        
        // Restore rax
        context.rax = rax;
        
        return true;
    }
    
    public synchronized bool task_switcher(InterruptStack* context)
    {
		if(currentThread !is null)
		{
			currentThread.saveContext(context);
			
			if(context.rax == ThreadState.Ready || context.rax == ThreadState.Waiting) 
			{
                currentThread.state = cast(ThreadState)context.rax;
			}
			else
			{
			    currentThread.state = ThreadState.Ready;
			}
			
			queue.enqueue(currentThread);
		}
		
		bool found = false;
		
		while(!found)
		{
            currentThread = queue.dequeue();
            
            if(currentThread.state == ThreadState.Ready || currentThread.state == ThreadState.New)
            {
                found = true;
            }
            else
            {
                queue.enqueue(currentThread);
            }
		}
		
		if(currentThread.state == ThreadState.New)
		{
			currentThread.saveContext(context);
			currentThread.init();
			currentThread.state = ThreadState.Ready;
		}
		
		currentThread.loadContext(context);
		
		currentThread.state = ThreadState.Running;
        
        return true;
    }
}
