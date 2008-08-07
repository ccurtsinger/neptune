/**
 * Physical page frame allocator
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.mem.physical;

import std.bit;
import std.stdio;

import kernel.core.env;

import util.arch.paging;

const ulong PAGE_BLOCK_SIZE = FRAME_SIZE * 8 * FRAME_SIZE; // The number of bytes that can tracked by a page-sized bitmap

const ulong PAGE_BLOCKS = PHYSICAL_MEM.top / PAGE_BLOCK_SIZE;

struct PageBlock
{
    private uint[FRAME_SIZE/4] bitmap;
    
    public void init()
    {
        for(size_t i=0; i<bitmap.length; i++)
        {
            bitmap[i] = 0;
        }
    }
    
    public int getAvailable()
    {
        for(size_t i=0; i<bitmap.length; i++)
        {
            if(bitmap[i] > 0)
            {
                size_t bitnum = bsf(bitmap[i]);
                
                btr(&(bitmap[i]), bitnum);
                
                return bitnum + 32*i;
            }
        }
        
        return -1;
    }
    
    public void setAvailable(size_t num, bool avl = true)
    {
        size_t bitnum = num % 32;
        
        size_t index = (num - bitnum) / 32;
        
        if(avl)
            bts(&(bitmap[index]), bitnum);
        else
            btr(&(bitmap[index]), bitnum);
    }
}

private PageBlock[PAGE_BLOCKS] blocks;

extern(C) void p_init()
{
    for(size_t i=0; i<blocks.length; i++)
    {
        blocks[i].init();
    }
}

extern(C) void p_free(size_t base)
{
    size_t offset = base % FRAME_SIZE;
    
    if(offset > 0)
        base += FRAME_SIZE - offset;
        
    size_t blockoffset = base % PAGE_BLOCK_SIZE;
    size_t blocknum = (base - blockoffset)/PAGE_BLOCK_SIZE;
    size_t pagenum = blockoffset / FRAME_SIZE;
    
    blocks[blocknum].setAvailable(pagenum);
}

extern(C) void p_set(size_t base)
{
    size_t offset = base % FRAME_SIZE;
    
    if(offset > 0)
        base += FRAME_SIZE - offset;

    size_t blockoffset = base % PAGE_BLOCK_SIZE;
    size_t blocknum = (base - blockoffset)/PAGE_BLOCK_SIZE;
    size_t pagenum = blockoffset / FRAME_SIZE;
    
    blocks[blocknum].setAvailable(pagenum, false);
}

extern(C) ulong p_alloc()
{
    for(size_t i=0; i<blocks.length; i++)
    {
        int index = blocks[i].getAvailable();
        
        if(index >= 0)
        {
            return PAGE_BLOCK_SIZE*cast(ulong)i + index*FRAME_SIZE;
        }
    }
    
    assert(false, "Out of memory");
}
