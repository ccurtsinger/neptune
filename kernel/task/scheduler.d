/**
 * Simple round-robin process scheduler
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.task.scheduler;

import util.arch.cpu;

import std.context;

import kernel.core.env;
import kernel.task.process;

class Scheduler
{
    private Process[] queue;
    private Process current;
    
    public this()
    {
        current = null;
    }
    
    public void add(Process p)
    {
        queue ~= p;
    }
    
    public void tick(Context* context)
    {
        if(queue.length > 0)
        {
            if(current !is null)
            {
                current.save(context);
                queue ~= current;
            }
            
            Process next = queue[0];
            queue = queue[1..length];
            
            current = next;
            
            next.run(context);
        }
    }
}
