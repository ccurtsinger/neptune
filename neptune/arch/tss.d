module neptune.arch.tss;

struct TSS
{
    align(1):

    uint res1;

    // Privelege-level switch stacks
    ulong rsp0;
    ulong rsp1;
    ulong rsp2;

    ulong res2;

    // Interrupt stack table
    ulong[7] ist;

    ulong res3;
    ushort res4;

    ushort iomap;

    ushort selector;

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
        rsp0 = 0;
        rsp1 = 0;
        rsp2 = 0;

        ist[0] = 0;
        ist[1] = 0;
        ist[2] = 0;
        ist[3] = 0;
        ist[4] = 0;
        ist[5] = 0;
        ist[6] = 0;
    }

    void setRspEntry(ubyte dpl, ulong p)
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

    void setIstEntry(size_t index, ulong p)
    {
        ist[index] = p;
    }

    void install()
    {
        asm
        {
            "ltr %[tssSel]" : : [tssSel] "b" selector;
        }
    }

    void setSelector(ushort s)
    {
        selector = s;
    }
}
