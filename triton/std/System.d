/**
 * Static System class used to access basic system components
 * i.e. standard i/o, filesystem(s), etc...
 *
 * Authors: Charlie Curtsinger
 * Date: November 5th, 2007
 * Version: 0.2a
 */
 
module std.System;

import std.io.CharStream;
import std.mem.AddressSpace;
import std.task.Scheduler;
import std.event.Dispatcher;

class System
{
    private static CharInputStream stdin = null;
    private static CharOutputStream stdout = null;
    private static CharOutputStream stderr = null;
    private static AddressSpace mem;
    private static Scheduler sched;
    private static Dispatcher disp;
    
    public static CharInputStream input()
    {
        return stdin;
    }
    
    public static void input(CharInputStream stdin)
    {
        this.stdin = stdin;
    }
    
    public static CharOutputStream output()
    {
        return stdout;
    }
    
    public static void output(CharOutputStream stdout)
    {
        this.stdout = stdout;
    }
    
    public static CharOutputStream error()
    {
        return stderr;
    }
    
    public static void error(CharOutputStream stderr)
    {
        this.stderr = stderr;
    }

    public static AddressSpace memory()
    {
        return mem;
    }
    
    public static void memory(AddressSpace mem)
    {
        this.mem = mem;
    }
    
    public static Scheduler scheduler()
    {
        return sched;
    }
    
    public static void scheduler(Scheduler sched)
    {
        this.sched = sched;
    }
    
    public static Dispatcher dispatcher()
    {
    	return disp;
    }
    
    public static void dispatcher(Dispatcher disp)
    {
    	this.disp = disp;
    }
}
