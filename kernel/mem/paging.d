module mem.paging;

const ubyte PAGEDIR_L4 = 39;
const ubyte PAGEDIR_L3 = 30;
const ubyte PAGEDIR_L2 = 21;
const ubyte PAGEDIR_L1 = 12;

const ulong PAGEDIR_ADDR_MASK = 0xFFFFFFFFFFFFF000;
const ulong PAGEDIR_ENTRY_MASK = 0xFFFFFFFFFFFFF000;

const ulong PAGE_PRESENT = 0x1;
const ulong PAGE_READWRITE = 0x2;
const ulong PAGE_USER = 0x4;
const ulong PAGE_WRITETHROUGH = 0x8;
const ulong PAGE_CACHE_DISABLE = 0x10;
const ulong PAGE_ACCESSED = 0x20;
const ulong PAGE_DIRTY = 0x40;
const ulong PAGE_GLOBAL = 0x100;
const ulong PAGE_COPY_ON_WRITE = 0x200;
const ulong PAGE_NX = 0x8000000000000000;

import mem.allocator;
import dev.screen;
import interrupt.idt;
import boot.kernel : pmem;

struct PageTable
{
    ulong* entries;
    ulong mask;
    ubyte lowBit;

    void init(ulong lowBit, ulong entries)
    {
        this.lowBit = lowBit;
        this.entries = cast(ulong*)(LINEAR_MEM_BASE + entries);

        mask = (cast(ulong)0x1FF)<<lowBit;
    }

    void init(ulong lowBit)
    {
        this.lowBit = lowBit;
        entries = cast(ulong*)(LINEAR_MEM_BASE + pmem.fetch());

        mask = (cast(ulong)0x1FF)<<lowBit;

        for(int i=0; i<FRAME_SIZE/ulong.sizeof; i++)
        {
            entries[i] = 0;
        }
    }

    new(ulong size, void* pos)
    {
        return pos;
    }

    bool present(ulong entry)
    {
        return (entry & 0x1) == 1;
    }

    void invalidate(ulong vAddr)
    {
        asm
        {
            "invlpg (%[addr])" : : [addr] "a" vAddr;
        }
    }

    bool map(ulong vAddr, ulong size = FRAME_SIZE, ulong flags = PAGE_PRESENT | PAGE_READWRITE)
    {
        ulong index = (vAddr & mask) >> lowBit;
        ulong topIndex = ((vAddr+size-1) & mask) >> lowBit;

        int conflicts = 0;

        //If we're not in the page table level (L1)
        if(lowBit > PAGEDIR_L1)
        {
            while(index <= topIndex)
            {
                //Page directory is present
                if(present(entries[index]))
                {
                    //Instantiate a lower page directory with data at the entry address
                    PageTable nextLevel;
                    nextLevel.init(lowBit-9, entries[index] & PAGEDIR_ADDR_MASK);

                    //Map into the lower directory
                    conflicts -= nextLevel.map(vAddr, size, flags);
                }
                //Page directory doesn't exist yet
                else
                {
                    //Create a new page directory of lower order
                    PageTable nextLevel;
                    nextLevel.init(lowBit-9);

                    //Put an entry in the current directory
                    entries[index] = ((cast(ulong)nextLevel.entries - LINEAR_MEM_BASE) & PAGEDIR_ENTRY_MASK) | flags;

                    //Map into the lower directory
                    conflicts -= nextLevel.map(vAddr, size, flags);
                }

                index++;
            }
        }

        //We're at the page table level
        else
        {
            while(index <= topIndex)
            {
                //Make sure an entry doesn't already exist at this virtual address
                if(!present(entries[index]))
                {
                    entries[index] = (pmem.fetch() & PAGEDIR_ENTRY_MASK) | flags;
                    invalidate(vAddr);
                }
                else
                {
                    conflicts++;
                }

                index++;
                vAddr += FRAME_SIZE;
            }
        }

        return conflicts == 0;
    }
}
