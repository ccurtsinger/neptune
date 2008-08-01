/**
 * Required support functions for the triton
 * runtime library
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core.host;

import std.stdio;

import util.arch.cpu;
import util.arch.arch;

import kernel.core.env;

extern(C) char _d_getc()
{
    assert(false, "_d_getc() is not yet implemented");
}

extern(C) void _d_error(char[] msg, char[] file, size_t line)
{
    CPU.disableInterrupts();
    
    writeln(msg);
	
	if(file !is null && line > 0)
	{
	    writefln(" (%s, line %u)", file, line);
	}
	
	version(unwind)
	{
	    stackUnwind(cast(ulong*)CPU.rsp, cast(ulong*)CPU.rbp);
	}
	
	for(;;){}
}

extern(C) void _d_abort()
{
    _d_error("Aborted", null, 0);
}

/**
 * Unit tests for the physical page frame allocator
 */
unittest
{
    ulong a = p_alloc();
    ulong b = p_alloc();
    
    p_free(a);
    
    ulong c = p_alloc();
    
    assert(a == c && b == a + FRAME_SIZE, "physical allocator unit test failed"); 
    
    p_free(b);
    p_free(c);
}

/**
 * Unit tests for the kernel heap allocator
 */
unittest
{
    void* a = m_alloc(ulong.sizeof);
    void* b = m_alloc(ulong.sizeof);
    
    assert(b >= a + ulong.sizeof, "heap allocator unit test failed");
    
    m_free(a);
    m_free(b);
}
