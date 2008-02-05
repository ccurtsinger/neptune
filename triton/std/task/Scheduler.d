
module std.task.Scheduler;

import std.task.Thread;

class Scheduler
{
    public abstract Thread current();
    
    public abstract synchronized void addThread(Thread t);
    
    public abstract synchronized void removeThread(Thread t);
    
    public abstract void taskSwitch(ThreadState s = ThreadState.Ready);
}
