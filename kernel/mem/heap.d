/**
 * Kernel Heap Allocator
 *
 * Copyright: 2008 The Neptune Project
 */
 
module kernel.mem.heap;

import kernel.arch.constants;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.range;

struct Block
{
    size_t size;
    Block* next;
}

AddressSpace* address_space;
ZoneType zone;

Block* freeblock = null;

void m_init(AddressSpace* init_address_space, ZoneType init_zone)
{
    address_space = init_address_space;
    zone = init_zone;
}
    
void* m_alloc(size_t size)
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
    
    MemoryRange m = address_space.allocate(zone, FRAME_SIZE);
    
    address_space.map(m.base, p_alloc(), Permission("---"), Permission("rw-"), false, false);
    
    Block* newblock = cast(Block*)m.base;
    newblock.size = m.size;
    newblock.next = null;
    
    m_free(cast(void*)newblock + Block.sizeof);
    
    return m_alloc(size);
}
    
size_t m_size(void* p)
{
    Block* b = cast(Block*)(p - Block.sizeof);
    
    return b.size - Block.sizeof;
}
    
void m_free(void* p)
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
