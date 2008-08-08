/**
 * Timer device
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.dev.timer;

import kernel.core.env;
import kernel.core.event;
import kernel.task.scheduler;

import std.stdio;
import std.context;

class Timer
{
    private ulong time;
    
    public this()
    {
        time = 0;

        root.addHandler("dev.timer", new DelegateEventHandler(&this.timer_interrupt));
    }
    
    public void timer_interrupt(char[] domain, EventSource source)
    {
        time++;
        
        InterruptEventSource i = cast(InterruptEventSource)source;
        
        if(i !is null)
            scheduler.tick(i.context);
    }
}
