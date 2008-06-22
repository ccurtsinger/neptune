/**
 * Kernel Heap Allocator
 *
 * Copyright: 2008 The Neptune Project
 */

import kernel.arch.constants;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.range;

import std.stdio;

struct Block
{
    size_t size;
    Block* next;
}

struct HeapAllocator
{
    private PhysicalAllocator* phys;
    private AddressSpace* addr;
    private ZoneType zone;
    
    private Block* freeblock = null;
    
    public static HeapAllocator opCall(PhysicalAllocator* phys, AddressSpace* addr, ZoneType zone)
    {
        HeapAllocator heap;
        heap.phys = phys;
        heap.addr = addr;
        heap.zone = zone;
        return heap;
    }
    
    public void* allocate(size_t size)
    {
        size_t allocated_size = size + Block.sizeof;
        
        Block* prev = null;
        Block* b = freeblock;
        
        while(b !is null)
        {
            if(b.size == allocated_size)
            {
                if(prev !is null)
                    prev.next = b.next;
                else
                    freeblock = b.next;
                
                b.next = null;
                
                return cast(void*)b + Block.sizeof;
            }
            else if(b.size > allocated_size)
            {
                Block* newblock = cast(Block*)(cast(void*)b + allocated_size);
                newblock.size = b.size - allocated_size;
                newblock.next = b.next;
                
                b.next = null;
                b.size = allocated_size;
                
                if(prev !is null)
                    prev.next = newblock;
                else
                    freeblock = newblock;
                
                return cast(void*)b + Block.sizeof;
            }
            
            prev = b;
            b = b.next;
        }
        
        MemoryRange m = addr.allocate(zone, FRAME_SIZE);
        
        addr.map(m.base, phys.allocate(), Permission("---"), Permission("rw-"), false, false);
        
        Block* newblock = cast(Block*)m.base;
        newblock.size = m.size;
        newblock.next = null;
        
        free(cast(void*)newblock + Block.sizeof);
        
        return allocate(size);
    }
    
    public void show()
    {
        Block* b = freeblock;
        
        while(b !is null)
        {
            writefln("%p to %p", b, cast(size_t)b + b.size);
            
            b = b.next;
        }
    }
    
    public size_t count()
    {
        size_t c = 0;
        
        Block* b = freeblock;
        
        while(b !is null)
        {
            c++;
            b = b.next;
        }
        
        return c;
    }
    
    public size_t size(void* p)
    {
        Block* b = cast(Block*)(p - Block.sizeof);
        
        return b.size - Block.sizeof;
    }
    
    public void free(void* p)
    {
        Block* newblock = cast(Block*)(p - Block.sizeof);
        
        Block* prev = null;
        
        if(freeblock is null)
        {
            freeblock = newblock;
            newblock.next = null;
        }
        else if(cast(size_t)freeblock > cast(size_t)newblock)
        {
            newblock.next = freeblock;
            freeblock = newblock;
        }
        else
        {
            bool inserted = false;
            
            Block* b = freeblock;

            while(!inserted)
            {
                if(cast(size_t)b < cast(size_t)newblock && (b.next is null || cast(size_t)b.next > cast(size_t)newblock))
                {
                    newblock.next = b.next;
                    b.next = newblock;
                    inserted = true;
                }

                prev = b;
                b = b.next;
            }
        }
        
        if(prev !is null && cast(size_t)prev + prev.size == cast(size_t)newblock)
        {
            prev.size += newblock.size;
            prev.next = newblock.next;
            newblock = prev;
        }
        
        if(newblock.next !is null && cast(size_t)newblock + newblock.size == cast(size_t)newblock.next)
        {
            newblock.size += newblock.next.size;
            newblock.next = newblock.next.next;
        }
    }
}
