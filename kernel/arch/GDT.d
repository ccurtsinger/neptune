module kernel.arch.GDT;

import kernel.arch.Descriptor;

struct GDT
{
    ulong[256] data;
    private size_t index = 0;
    
    public void init()
    {
        index = 0;
    }
    
    public T* getEntry(T)()
    {
        size_t i;
        
        i = index;
        index += T.sizeof/ulong.sizeof;
        
        return cast(T*)&(data[i]);
    }
    
    public ushort getSelector()
    {
        return ulong.sizeof * index;
    }
    
    public void install()
    {
        DTPtr gdtp;
        
        gdtp.limit = index * 8 - 1;
        gdtp.address = data.ptr;

        asm
        {
            "cli";
            "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
        }
    }
}
