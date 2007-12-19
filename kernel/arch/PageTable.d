module kernel.arch.PageTable;

import std.bitarray;

import kernel.arch.Arch;

struct Page
{
    ulong data;
    
    static Page opCall()
    {
        Page p;
        p.present = false;
        return p;
    }
    
    bool present()
    {
        return BitArray(&data, 64)[0];
    }
    
    void present(bool b)
    {
        BitArray(&data, 64)[0] = b;
    }
    
    bool writable()
    {
        return BitArray(&data, 64)[1];
    }
    
    void writable(bool b)
    {
        BitArray(&data, 64)[1] = b;
    }
    
    bool superuser()
    {
        return BitArray(&data, 64)[2];
    }
    
    void superuser(bool b)
    {
        BitArray(&data, 64)[2] = b;
    }
    
    bool writethrough()
    {
        return BitArray(&data, 64)[3];
    }
    
    void writethrough(bool b)
    {
        BitArray(&data, 64)[3] = b;
    }
    
    bool nocache()
    {
        return BitArray(&data, 64)[4];
    }
    
    void nocache(bool b)
    {
        BitArray(&data, 64)[4] = b;
    }
    
    bool accessed()
    {
        return BitArray(&data, 64)[5];
    }
    
    void accessed(bool b)
    {
        BitArray(&data, 64)[5] = b;
    }
    
    bool dirty()
    {
        return BitArray(&data, 64)[6];
    }
    
    void dirty(bool b)
    {
        BitArray(&data, 64)[6] = b;
    }
    
    bool pat()
    {
        return BitArray(&data, 64)[7];
    }
    
    void pat(bool b)
    {
        BitArray(&data, 64)[7] = b;
    }
    
    bool global()
    {
        return BitArray(&data, 64)[8];
    }
    
    void global(bool b)
    {
        BitArray(&data, 64)[8] = b;
    }
    
    bool noexecute()
    {
        return BitArray(&data, 64)[63];
    }
    
    void noexecute(bool b)
    {
        BitArray(&data, 64)[63] = b;
    }
    
    ulong address()
    {
        return data & 0x0007FFFFFFFFF000;
    }
    
    void address(ulong addr)
    {
        addr &= 0x0007FFFFFFFFF000;
        data &= 0xFFF8000000000FFF;
        data |= addr;
    }
    
    public void invalidate()
    {
        asm
        {
            "invlpg (%[address])" : : [address] "a" address();
        }
    }
}

void spin()
{
    char* c = cast(char*)0xFFFF8300000B8000;
    
    while(true)
    {
        for(int i=0; i<80*24; i++)
        {
            c[2*i]++;
        }
    }
}

void show(char[] str)
{
    char* screen = cast(char*)0xFFFF8300000B8000;
    
    foreach(size_t i, char c; str)
    {
        screen[2*i] = c;
    }
}

void show(ulong u)
{
    char[17] str;
    itoa(u, str.ptr, 16);
    show(str);
}

import std.integer;
import std.stdmem;

class VirtualMemory
{
    Page* table;
    
    public this(paddr_t address)
    {
        table = cast(Page*)ptov(address);
    }
    
    private size_t getIndex(size_t level, ulong address)
    {
        return (address >> (3 + level*9)) & 0x1FF;
    }
    
    public Page* opIndex(vaddr_t address)
    {
        return opIndex(cast(size_t)address);
    }
    
    public Page* opIndex(size_t address)
    {
        Page* t = table;
        size_t level = 4;
        
        while(level > 1)
        {
            size_t index = getIndex(level, address);

            if(!t[index].present)
            {
                t[index].writable = true;
                t[index].superuser = false;
                t[index].writethrough = false;
                t[index].nocache = false;
                t[index].accessed = false;
                t[index].dirty = false;
                t[index].pat = false;
                t[index].global = false;
                
                ulong a = System.memory.physical.getPage();
                
                memset(ptov(a), 0, 4096);
                
                t[index].address = a;
                
                t[index].noexecute = false;
                t[index].present = true;
            }
            
            t = cast(Page*)ptov(t[index].address);
            
            level--;
        }
        
        size_t index = getIndex(level, address);
        
        return &(t[index]);
    }
    
    public Page* opIndex2(size_t address)
    {
        Page* t = table;
        size_t level = 4;
        
        spin();
        
        while(level > 1)
        {
            size_t index = getIndex(level, address);

            if(!t[index].present)
            {
                t[index].writable = true;
                t[index].superuser = false;
                t[index].writethrough = false;
                t[index].nocache = false;
                t[index].accessed = false;
                t[index].dirty = false;
                t[index].pat = false;
                t[index].global = false;
                
                ulong a = System.memory.physical.getPage();
                
                memset(ptov(a), 0, 4096);
                
                t[index].address = a;
                
                t[index].noexecute = false;
                t[index].present = true;
            }
            
            t = cast(Page*)ptov(t[index].address);
            
            level--;
        }
        
        size_t index = getIndex(level, address);
        
        return &(t[index]);
    }
}

struct PageTable
{
    Page[512] table;
    
    private size_t getIndex(size_t level, ulong address)
    {
        return (address >> (3 + level*9)) & 0x1FF;
    }
    
    public Page* opIndex(vaddr_t address)
    {
        return opIndex(cast(size_t)address);
    }
    
    public Page* opIndex(size_t address)
    {
        Page* t = table.ptr;
        size_t level = 4;
        
        while(level > 1)
        {
            size_t index = getIndex(level, address);

            if(!t[index].present)
            {
                t[index].writable = true;
                t[index].superuser = false;
                t[index].writethrough = false;
                t[index].nocache = false;
                t[index].accessed = false;
                t[index].dirty = false;
                t[index].pat = false;
                t[index].global = false;
                
                ulong a = System.memory.physical.getPage();
                
                memset(ptov(a), 0, 4096);
                
                t[index].address = a;
                
                t[index].noexecute = false;
                t[index].present = true;
            }
            
            t = cast(Page*)ptov(t[index].address);
            
            level--;
        }
        
        size_t index = getIndex(level, address);
        
        return &(t[index]);
    }
}
