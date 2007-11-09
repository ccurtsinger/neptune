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
import std.mem.Allocator;
import std.mem.PageAllocator;

class System
{
    private static CharInputStream stdin = null;
    private static CharOutputStream stdout = null;
    private static CharOutputStream stderr = null;
    private static PageAllocator pmem = null;
    private static Allocator mem = null;
    
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
    
    public static void setPhysicalAllocator(PageAllocator p)
    {
        pmem = p;
    }
    
    public static void setAllocator(Allocator a)
    {
        mem = a;
    }
    
    public static ulong getPage()
    {
        return pmem.getPage();
    }
    
    public static void* allocate(size_t size)
    {
        return mem.allocate(size);
    }
    
    public static void free(void* p)
    {
        return mem.free(p);
    }
}
