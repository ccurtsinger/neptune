/**
 * Timer device
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.dev.timer;

import kernel.core.env;
import kernel.task.scheduler;

import std.stdio;
import std.context;

class Timer
{
    private ulong time;
    
    public this(ubyte interrupt)
    {
        time = 0;

        localscope.setHandler(interrupt, &timer_interrupt);
    }
    
    public bool timer_interrupt(Context* context)
    {
        time++;
        
        scheduler.tick(context);
        
        return true;
    }
}
