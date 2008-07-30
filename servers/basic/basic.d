/**
 * A simple test server implementation
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

import std.activation;
import std.context;

ulong function(ulong) syscall;

extern(C) int _start(Activation* sa, ulong s)
{
    syscall = cast(ulong function(ulong))s;
    
    if(sa.type == SA_NEW)
    {
        thread();
    }
    else if(sa.type == SA_PREEMPTED)
    {
        sa.context.load();
    }
    
	for(;;){}
	
	return 0;
}

void thread()
{
    ulong x;
    
    while(1 < 2)
    {
        x = syscall(x);
    }
}

extern(C) void _d_allocsize()
{
    return 0;
}

extern(C) void _d_malloc()
{

}

extern(C) void _d_free()
{
    
}

extern(C) void _d_palloc()
{
    
}

extern(C) void _d_error()
{
    
}

extern(C) void _d_abort()
{
    
}
