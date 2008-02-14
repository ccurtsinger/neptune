module kernel.core.host;

import std.stdio;

import arch.x86_64.arch;

import kernel.core.env;

extern(C) void* _d_malloc(size_t size)
{
    return heap.get(size);
}

extern(C) size_t _d_palloc()
{
    return physical.get();
}

extern(C) size_t _d_allocsize(void* p)
{
    assert(false, "_d_allocsize() is not yet implemented");
}

extern(C) void _d_free(void* p)
{
    // Do nothing for now
}

extern(C) void _d_pfree(size_t p)
{
    physical.add(p, FRAME_SIZE);
}

extern(C) void _d_putc(char c)
{
    screen.putc(c);
}

extern(C) char _d_getc()
{
    assert(false, "_d_getc() is not yet implemented");
}

extern(C) void _d_error(char[] msg, char[] file, size_t line)
{
    write(msg);
	
	if(file !is null && line > 0)
	{
	    writef(" (%s, line %u)", file, line);
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
    ulong a = _d_palloc();
    ulong b = _d_palloc();
    
    _d_pfree(a);
    
    ulong c = _d_palloc();
    
    assert(a == c && b == a + FRAME_SIZE, "physical allocator unit test failed"); 
    
    _d_pfree(b);
    _d_pfree(c);
}

/**
 * Unit tests for the kernel heap allocator
 */
unittest
{
    void* a = _d_malloc(ulong.sizeof);
    void* b = _d_malloc(ulong.sizeof);
    
    assert(b >= a + ulong.sizeof, "heap allocator unit test failed");
    
    _d_free(a);
    _d_free(b);
}
