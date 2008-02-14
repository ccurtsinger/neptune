module kernel.core.env;

import arch.x86_64.arch;
import arch.x86_64.cpu;

import kernel.dev.screen;
import kernel.dev.kb;

import kernel.core.interrupt;

import kernel.mem.physical;
import kernel.mem.kernel;

Screen* screen;
Keyboard kb;

PhysicalMemory physical;
KernelMemory heap;

CPU cpu;

InterruptScope localscope;

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
