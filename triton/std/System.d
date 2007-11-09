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
import std.task.Thread;

class System
{
    private static CharInputStream stdin = null;
    private static CharOutputStream stdout = null;
    private static CharOutputStream stderr = null;
    private static AddressSpace mem;
    private static Thread currentThread;
    
    public static CharInputStream input()
    {
        return stdin;
    }
    
    public static CharOutputStream output()
    {
        return stdout;
    }
    
    public static CharOutputStream error()
    {
        return stderr;
    }
    
    public static void setInput(CharInputStream stdin)
    {
        this.stdin = stdin;
    }
    
    public static void setOutput(CharOutputStream stdout)
    {
        this.stdout = stdout;
    }
    
    public static void setError(CharOutputStream stderr)
    {
        this.stderr = stderr;
    }
    
    public static size_t pageSize()
    {
        return 0x1000;
    }
    
    public static void setMemory(AddressSpace mem)
    {
        this.mem = mem;
    }
    
    public static AddressSpace memory()
    {
        return mem;
    }
    
    public static void setThread(Thread currentThread)
    {
        this.currentThread = currentThread;
    }
    
    public static Thread thread()
    {
        return currentThread;
    }
}
