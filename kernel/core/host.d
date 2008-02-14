module kernel.core.host;

public import arch.x86_64.arch;
public import arch.x86_64.cpu;
public import arch.x86_64.paging;
public import arch.x86_64.descriptor;
public import arch.x86_64.gdt;
public import arch.x86_64.idt;

import std.stdio;

public import kernel.dev.screen;
public import kernel.dev.kb;

public import kernel.core.interrupt;

public import kernel.mem.physical;
public import kernel.mem.kernel;

Screen* screen;
Keyboard kb;

PhysicalMemory physical;
KernelMemory heap;

CPU cpu;

InterruptScope localscope;

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
 * Data passed from the 32 bit loader
 */
struct LoaderData
{
	ulong L4;
	
	ulong usedMemBase;
	ulong usedMemSize;
	
	ulong lowerMemBase;
	ulong lowerMemSize;
	
	ulong upperMemBase;
	ulong upperMemSize;
	
	ulong regions;
	MemoryRegion* memInfo;
	
	ulong tempData;
	size_t tempDataSize;
}

struct MemoryRegion
{
    ulong base;
    ulong length;
    ulong type;
}

struct InterruptStack
{
	ulong rax;
	ulong rbx;
	ulong rcx;
	ulong rdx;
	ulong rsi;
	ulong rdi;
	ulong r8;
	ulong r9;
	ulong r10;
	ulong r11;
	ulong r12;
	ulong r13;
	ulong r14;
	ulong r15;
	ulong rbp;
	ulong error;
	ulong rip;
	ulong cs;
	ulong rflags;
	ulong rsp;
	ulong ss;
}
