module kernel.arch.TSS;

class TSS
{
    struct TSSData
    {
        align(1):

        uint res1 = 0;

        // Privelege-level switch stacks
        ulong[3] rsp;

        // Interrupt stack table (ist[0] is invalid)
        ulong[8] ist;

        ulong res3;
        ushort res4;

        ushort iomap;
    }
    
    private TSSData data;
    
    private ushort s;
    
    public void install()
    {
        asm
        {
            "ltr %[tssSel]" : : [tssSel] "b" s;
        }
    }
    
    public ushort selector()
    {
        return s;
    }
    
    public void selector(ushort selector)
    {
        this.s = s;
    }
    
    public ulong address()
    {
        return cast(ulong)&data;
    }
    
    public ulong rsp0()
    {
        return data.rsp[0];
    }
    
    public void rsp0(ulong i)
    {
        data.rsp[0] = i;
    }
    
    public ulong rsp1()
    {
        return data.rsp[1];
    }
    
    public void rsp1(ulong i)
    {
        data.rsp[1] = i;
    }
    
    public ulong rsp2()
    {
        return data.rsp[2];
    }
    
    public void rsp2(ulong i)
    {
        data.rsp[2] = i;
    }
    
    public ulong ist1()
    {
        return data.ist[1];
    }
    
    public void ist1(ulong i)
    {
        data.ist[1] = i;
    }
    
    public ulong ist2()
    {
        return data.ist[2];
    }
    
    public void ist2(ulong i)
    {
        data.ist[2] = i;
    }
    
    public ulong ist3()
    {
        return data.ist[3];
    }
    
    public void ist3(ulong i)
    {
        data.ist[3] = i;
    }
    
    public ulong ist4()
    {
        return data.ist[4];
    }
    
    public void ist4(ulong i)
    {
        data.ist[4] = i;
    }
    
    public ulong ist5()
    {
        return data.ist[5];
    }
    
    public void ist5(ulong i)
    {
        data.ist[5] = i;
    }
    
    public ulong ist6()
    {
        return data.ist[6];
    }
    
    public void ist6(ulong i)
    {
        data.ist[6] = i;
    }
    
    public ulong ist7()
    {
        return data.ist[7];
    }
    
    public void ist7(ulong i)
    {
        data.ist[7] = i;
    }
}
