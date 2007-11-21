
module std.task.Scheduler;

import std.task.Thread;

class Scheduler
{
    public abstract void addThread(Thread t);
    
    public abstract ulong addThread(void function() thread);
    
    public abstract Thread thread();
    
    public abstract void yield();
    
    public abstract void exit();
}
