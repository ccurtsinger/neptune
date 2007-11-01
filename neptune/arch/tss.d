/**
 * TSS abstraction
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module neptune.arch.tss;

/**
 * TSS object
 */
struct TSS
{
    align(1):

    uint res1;

    // Privelege-level switch stacks
    void* rsp0;
    void* rsp1;
    void* rsp2;

    ulong res2;

    // Interrupt stack table
    void*[7] ist;

    ulong res3;
    ushort res4;

    ushort iomap;

    ushort selector;

	/**
	 * Initialize the TSS
	 *
	 * Sets all reserved and available regions to 0
	 */
    void init()
    {
        // Clear reserved regions
        res1 = 0;
        res2 = 0;
        res3 = 0;
        res4 = 0;

        // Clear iomap - currently unsupported
        iomap = 0;

        // Clear pointers
        rsp0 = null;
        rsp1 = null;
        rsp2 = null;

        ist[0] = null;
        ist[1] = null;
        ist[2] = null;
        ist[3] = null;
        ist[4] = null;
        ist[5] = null;
        ist[6] = null;
    }

	/**
	 * Set one of the permission-level stack pointers
	 *
	 * Params:
	 *  dpl = Privelege level
	 *  p = Stack pointer
	 */
    void setRspEntry(ubyte dpl, void* p)
    {
        if(dpl == 0)
        {
            rsp0 = p;
        }
        else if(dpl == 1)
        {
            rsp1 = p;
        }
        else
        {
            rsp2 = p;
        }
    }

	/**
	 * Set one of the interrupt stack table entries
	 *
	 * Params:
	 *  index = Index into the IST
	 *  p = Stack pointer
	 */
    void setIstEntry(size_t index, void* p)
    {
        ist[index] = p;
    }

	/**
	 * Set the offset of the TSS entry in the GDT
	 *
	 * Params:
	 *  s = GDT offset
	 */
	void setSelector(ushort s)
    {
        selector = s;
    }

	/**
	 * Install the TSS
	 */
    void install()
    {
        asm
        {
            "ltr %[tssSel]" : : [tssSel] "b" selector;
        }
    }
}
