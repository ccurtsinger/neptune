/**
 * Abstraction for the long-mode TSS
 *
 * Copyright: 2008 The Neptune Project
 */

module util.arch.TSS;

/**
 * TSS abstraction
 */
struct TSS
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
    
    private ushort s;
    
    public void init()
    {
        res1 = 0;

        res3 = 0;
        res4 = 0;
        
        iomap = 0;
        
        rsp[0] = 0;
        rsp[1] = 0;
        rsp[2] = 0;
        
        ist[0] = 0;
        ist[1] = 0;
        ist[2] = 0;
        ist[3] = 0;
        ist[4] = 0;
        ist[5] = 0;
        ist[6] = 0;
        ist[7] = 0;
    }
    
    /**
     * Load the TSS
     */
    public void install()
    {
        asm
        {
            "ltr %[tssSel]" : : [tssSel] "b" s;
        }
    }
    
    /**
     * Get the GDT selector for the TSS descriptor
     */
    public ushort selector()
    {
        return s;
    }
    
    /**
     * Set the selector for the GDT TSS descriptor
     */
    public void selector(ushort selector)
    {
        this.s = selector;
    }
    
    /**
     * Get the TSS data address
     */
    public ulong address()
    {
        return cast(ulong)this;
    }
    
    /**
     * Get the dpl 0 stack pointer
     */
    public ulong rsp0()
    {
        return rsp[0];
    }
    
    /**
     * set the dpl 0 stack pointer
     */
    public void rsp0(ulong i)
    {
        rsp[0] = i;
    }
    
    /**
     * get the dpl 1 stack pointer
     */
    public ulong rsp1()
    {
        return rsp[1];
    }
    
    /**
     * set the dpl 1 stack pointer
     */
    public void rsp1(ulong i)
    {
        rsp[1] = i;
    }
    
    /**
     * Get the dpl 2 stack pointer
     */
    public ulong rsp2()
    {
        return rsp[2];
    }
    
    /**
     * Set the dpl 2 stack pointer
     */
    public void rsp2(ulong i)
    {
        rsp[2] = i;
    }
    
    /**
     * Get the IST index 1 address
     */
    public ulong ist1()
    {
        return ist[1];
    }
    
    /**
     * Set the IST index 1 address
     */
    public void ist1(ulong i)
    {
        ist[1] = i;
    }
    
    /**
     * Get the IST index 2 address
     */
    public ulong ist2()
    {
        return ist[2];
    }
    
    /**
     * Set the IST index 2 address
     */
    public void ist2(ulong i)
    {
        ist[2] = i;
    }
    
    /**
     * Get the IST index 3 address
     */
    public ulong ist3()
    {
        return ist[3];
    }
    
    /**
     * Set the IST index 3 address
     */
    public void ist3(ulong i)
    {
        ist[3] = i;
    }
    
    /**
     * Get the IST index 4 address
     */
    public ulong ist4()
    {
        return ist[4];
    }
    
    /**
     * Set the IST index 4 address
     */
    public void ist4(ulong i)
    {
        ist[4] = i;
    }
    
    /**
     * Get the IST index 5 address
     */
    public ulong ist5()
    {
        return ist[5];
    }
    
    /**
     * Set the IST index 5 address
     */
    public void ist5(ulong i)
    {
        ist[5] = i;
    }
    
    /**
     * Get the IST index 6 address
     */
    public ulong ist6()
    {
        return ist[6];
    }
    
    /**
     * Set the IST index 6 address
     */
    public void ist6(ulong i)
    {
        ist[6] = i;
    }
}
