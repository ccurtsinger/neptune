
module kernel.task.Thread;

import std.task.Thread;
import kernel.event.Interrupt;

static this()
{
	Thread.nextID = 0;
}

class KernelThread : Thread
{
	private InterruptStack context;
	
    private void function() task;
    
    public this(void function() task)
    {
        this.task = task;
        
        super();
    }
    
    public void init()
    {
    	void delegate() r = &this.run;
		
		context.rip = cast(ulong)r.funcptr;
		context.rdi = cast(ulong)r.ptr;
		context.rsp = cast(ulong)System.mem.stack.allocate();
    }
    
    protected void run()
    {
        task();
        
        System.output.writef("Thread %u returned", id).newline;
        
        for(;;){}
    }
    
    public synchronized void saveContext(void* context)
    {
    	this.context = *cast(InterruptStack*)context;
    }
    
    public synchronized void loadContext(void* context)
    {
    	*cast(InterruptStack*)context = this.context;
    }
}
