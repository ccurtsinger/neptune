/**
 * Abstraction for a virtual memory address space
 *
 * Authors: Charlie Curtsinger
 * Date: November 7th, 2007
 * Version: 0.2a
 */

import std.stdlib;

import neptune.arch.paging;

class AddressSpace
{
	VirtualMemory* mem;
	
	void* nextStack;
	size_t stackSize;
	
	this(VirtualMemory* mem)
	{
		this.mem = mem;
		nextStack = cast(void*)0x100000000;
		stackSize = 4;
	}
	
	public void* getStack()
	{
		void* top = nextStack;
		
		for(int i=0; i<stackSize; i++)
		{
			mem.map(nextStack);
			nextStack -= FRAME_SIZE;
		}
		
		return top;
	}
}
