/**
 * A simple test server implementation
 *
 * Copyright: 2008 The Neptune Project
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

extern(C) void m_size()
{
    return 0;
}

extern(C) void m_alloc()
{

}

extern(C) void m_free()
{
    
}

extern(C) void p_alloc()
{
    
}

extern(C) void _d_error()
{
    
}

extern(C) void _d_abort()
{
    
}
