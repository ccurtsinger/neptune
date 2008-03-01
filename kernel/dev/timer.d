/**
 * Timer device
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module kernel.dev.timer;

import kernel.core.env;
import kernel.core.interrupt;
import kernel.task.scheduler;
import kernel.task.thread;
import kernel.task.waitqueue;

class Timer
{
    private WaitQueue queue;
    private ulong time;
    
    public this(ubyte interrupt)
    {
        queue = new WaitQueue();
        time = 0;
        
        localscope.setHandler(interrupt, &timer_interrupt);
    }
    
    public ulong getTime()
    {
        return time;
    }
    
    public void wait(ulong delay, InterruptStack* context)
    {
        Thread t = scheduler.removeCurrent(context);
    
        queue.add(new WaitCondition(t, time + delay));
    
        scheduler.taskSwitch(context);
    }
    
    public bool timer_interrupt(InterruptStack* context)
    {
        time++;

        while(queue.length > 0 && time >= queue.peek().value)
        {
            WaitCondition c = queue.get();
            
            scheduler.addThread(c.thread);
            
            delete c;
        }

        scheduler.taskSwitch(context);
        
        return true;
    }
}
