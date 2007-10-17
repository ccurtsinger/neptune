module neptune.arch.gdt;

import std.bitarray;

enum GDTEntryType
{
    NULL,
    CODE,
    DATA,
    TSS
}

enum DPL
{
    KERNEL,
    SERVER,
    USER
}

struct GDTEntry
{
    ulong data1;
    ulong data2;
    GDTEntryType type;

    static GDTEntry opCall(GDTEntryType t, DPL p = DPL.KERNEL)
    {
        GDTEntry entry;

        entry.type = t;

        if(t == GDTEntryType.NULL)
        {
            entry.data1 = 0;
        }
        else if(t == GDTEntryType.CODE || t == GDTEntryType.DATA)
        {
            auto b = BitArray(&entry.data1, 64);

            // Clear base and limit bits (ignored in long mode)
            b[0..40] = 0;
            b[48..52] = 0;
            b[56..64] = 0;

            // Set long mode bit
            b[53] = 1;

            // Clear operand size bit (required for long mode)
            b[54] = 0;

            // Clear granularity bit (ignored in long mode)
            b[55] = 0;

            // Set DPL
            b[45..47] = p;

            // Set present bit
            b[47] = 1;

            // Set type-specific bits
            if(t == GDTEntryType.CODE)
            {
                // Set accessed bit to 0
                b[40] = 0;

                // Set readable bit to 1 (ignored in long mode)
                b[41] = 1;

                // Set conforming segment bit
                b[42] = 1;

                // Set type to code segment
                b[43..45] = 3;
            }
            else
            {
                // Set accessed bit to 0
                b[40] = 0;

                // Set writable bit to 1 (ignored in long mode)
                b[41] = 1;

                // Set expand-down bit to 1 (ignored in long mode)
                b[42] = 1;

                // Set type to data segment
                b[43..45] = 2;
            }
        }

        return entry;
    }
}

struct GDT
{
    ulong[256] entries;
    GDTPtr gdtp;

    ubyte index = 0;

    TSS tss;
    ushort tssSel;

    void addEntry(GDTEntry e)
    {
        entries[index] = e.data1;

        if(e.type == GDTEntryType.TSS)
        {
            entries[index+1] = e.data2;
            index++;
        }
        index++;
    }

    void install()
    {
        GDTEntry e;

        addEntry(GDTEntry(GDTEntryType.NULL));

        addEntry(GDTEntry(GDTEntryType.CODE, DPL.KERNEL));

        addEntry(GDTEntry(GDTEntryType.DATA, DPL.KERNEL));

        addEntry(GDTEntry(GDTEntryType.CODE, DPL.USER));

        addEntry(GDTEntry(GDTEntryType.DATA, DPL.USER));

        //TSS Descriptor

        // Set limit
        entries[5] = 0x67;

        // Set base bytes 1, 2, and 3
        entries[5] |= (cast(ulong)&tss << 16) & 0xFFFFFF0000L;

        // Set base byte 4
        entries[5] |= (cast(ulong)&tss << 32) & 0xFF00000000000000L;

        // Set P, DPL, and type
        entries[5] |= 0x0000890000000000L;

        entries[6] = 0;
        entries[6] = (cast(ulong)&tss >> 32) & 0xFFFFFFFFL;

        gdtp.limit = 7 * ulong.sizeof - 1;
        gdtp.address = cast(ulong)(&(entries[0]));

        // Set up TSS
        tss.res1 = 0;
        tss.res2 = 0;
        tss.res3 = 0;
        tss.res4 = 0;
        tss.iomap = 0;

        tss.rsp0 = 0xFFFF810000000000;
        tss.rsp1 = 0xFFFF810000000000;
        tss.rsp2 = 0xFFFF810000000000;

        tss.ist[0] = 0x7FFFFFF8;
        tss.ist[1] = 0x7FFFFFF8;
        tss.ist[2] = 0x7FFFFFF8;
        tss.ist[3] = 0x7FFFFFF8;
        tss.ist[4] = 0x7FFFFFF8;
        tss.ist[5] = 0x7FFFFFF8;
        tss.ist[6] = 0x7FFFFFF8;

        tssSel = 0x28;

        asm
        {
            "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
            "ltr %[tssSel]" : : [tssSel] "b" tssSel;
        }
    }
}

struct GDTPtr
{
    align(1):
    ushort limit;
    ulong address;
}

struct TSS
{
    align(1):

    uint res1;

    ulong rsp0;
    ulong rsp1;
    ulong rsp2;

    ulong res2;

    ulong[7] ist;

    ulong res3;
    ushort res4;

    ushort iomap;
}
