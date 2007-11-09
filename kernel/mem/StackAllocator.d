
module kernel.mem.StackAllocator;

import std.mem.BlockAllocator;
import neptune.arch.paging;

class StackAllocator : BlockAllocator
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
	
	public void* allocate()
	{
		void* top = nextStack;
		
		for(int i=0; i<stackSize; i++)
		{
			mem.map(nextStack);
			nextStack -= System.pageSize;
		}
		
		return top;
	}
	
	public void free(void* p)
	{
	    // Do nothing
	}
	
	public void add(void* base, size_t limit)
	{
	    // Not used yet
	}
    
    public size_t getBlockSize()
    {
        return System.pageSize * stackSize;
    }
    
    public size_t getFreeSize()
    {
        return cast(size_t)nextStack;
    }
    
    public size_t getAllocatedSize()
    {
        return cast(size_t)nextStack - 0x100000000;
    }
    
    public size_t getOverheadSize()
    {
        return 0;
    }
}
