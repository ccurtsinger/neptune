/**
 * Abstraction for the long-mode TSS
 *
 * Authors: Charlie Curtsinger
 * Date: January 15th, 2008
 * Version: 0.2a
 */

module kernel.arch.TSS;

/**
 * TSS abstraction
 */
class TSS
{
	/**
	 * Struct representation of the TSS data
	 */
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
        this.s = s;
    }
    
    /**
     * Get the TSS data address
     */
    public ulong address()
    {
        return cast(ulong)&data;
    }
    
    /**
     * Get the dpl 0 stack pointer
     */
    public ulong rsp0()
    {
        return data.rsp[0];
    }
    
    /**
     * set the dpl 0 stack pointer
     */
    public void rsp0(ulong i)
    {
        data.rsp[0] = i;
    }
    
    /**
     * get the dpl 1 stack pointer
     */
    public ulong rsp1()
    {
        return data.rsp[1];
    }
    
    /**
     * set the dpl 1 stack pointer
     */
    public void rsp1(ulong i)
    {
        data.rsp[1] = i;
    }
    
    /**
     * Get the dpl 2 stack pointer
     */
    public ulong rsp2()
    {
        return data.rsp[2];
    }
    
    /**
     * Set the dpl 2 stack pointer
     */
    public void rsp2(ulong i)
    {
        data.rsp[2] = i;
    }
    
    /**
     * Get the IST index 1 address
     */
    public ulong ist1()
    {
        return data.ist[1];
    }
    
    /**
     * Set the IST index 1 address
     */
    public void ist1(ulong i)
    {
        data.ist[1] = i;
    }
    
    /**
     * Get the IST index 2 address
     */
    public ulong ist2()
    {
        return data.ist[2];
    }
    
    /**
     * Set the IST index 2 address
     */
    public void ist2(ulong i)
    {
        data.ist[2] = i;
    }
    
    /**
     * Get the IST index 3 address
     */
    public ulong ist3()
    {
        return data.ist[3];
    }
    
    /**
     * Set the IST index 3 address
     */
    public void ist3(ulong i)
    {
        data.ist[3] = i;
    }
    
    /**
     * Get the IST index 4 address
     */
    public ulong ist4()
    {
        return data.ist[4];
    }
    
    /**
     * Set the IST index 4 address
     */
    public void ist4(ulong i)
    {
        data.ist[4] = i;
    }
    
    /**
     * Get the IST index 5 address
     */
    public ulong ist5()
    {
        return data.ist[5];
    }
    
    /**
     * Set the IST index 5 address
     */
    public void ist5(ulong i)
    {
        data.ist[5] = i;
    }
    
    /**
     * Get the IST index 6 address
     */
    public ulong ist6()
    {
        return data.ist[6];
    }
    
    /**
     * Set the IST index 6 address
     */
    public void ist6(ulong i)
    {
        data.ist[6] = i;
    }
    
    /**
     * Get the IST index 7 address
     */
    public ulong ist7()
    {
        return data.ist[7];
    }
    
    /**
     * Set the IST index 7 address
     */
    public void ist7(ulong i)
    {
        data.ist[7] = i;
    }
}
