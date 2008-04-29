/**
 * Physical page-frame allocator
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module kernel.mem.physical;

import util.arch.arch;

import std.bit;
import std.stdio;

import kernel.core.env;

const ulong PAGE_BLOCK_SIZE = FRAME_SIZE * 8 * FRAME_SIZE; // The number of bytes that can tracked by a page-sized bitmap

const ulong MAX_MEMORY = 0x100000000; // 4GB for now

const ulong PAGE_BLOCKS = MAX_MEMORY / PAGE_BLOCK_SIZE;

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

struct PhysicalMemory
{
    private PageBlock[PAGE_BLOCKS] blocks;
    
    public void init()
    {
        for(size_t i=0; i<blocks.length; i++)
        {
            blocks[i].init();
        }
    }
    
    public void add(size_t base, size_t size)
    {
        size_t offset = base % FRAME_SIZE;
        
        if(offset > 0)
            base += FRAME_SIZE - offset;
        
        size -= size % FRAME_SIZE;
        
        for(size_t i=0; i<size; i+= FRAME_SIZE)
        {
            size_t addr = i + base;
            size_t blockoffset = addr % PAGE_BLOCK_SIZE;
            size_t blocknum = (addr - blockoffset)/PAGE_BLOCK_SIZE;
            size_t pagenum = blockoffset / FRAME_SIZE;
            
            blocks[blocknum].setAvailable(pagenum);
        }
    }
    
    public void remove(size_t base, size_t size)
    {
        size_t offset = base % FRAME_SIZE;
        
        if(offset > 0)
            base += FRAME_SIZE - offset;
        
        size -= size % FRAME_SIZE;
        
        for(size_t i=0; i<size; i+= FRAME_SIZE)
        {
            size_t addr = i + base;
            size_t blockoffset = addr % PAGE_BLOCK_SIZE;
            size_t blocknum = (addr - blockoffset)/PAGE_BLOCK_SIZE;
            size_t pagenum = blockoffset / FRAME_SIZE;
            
            blocks[blocknum].setAvailable(pagenum, false);
        }
    }
    
    public ulong get()
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
}
