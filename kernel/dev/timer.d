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
import kernel.task.procallocator;

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
        
        procalloc.tick(context);
        
        return true;
    }
}
