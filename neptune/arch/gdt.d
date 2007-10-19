module neptune.arch.gdt;

import std.bitarray;
import neptune.arch.tss;

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

    static GDTEntry opCall(ulong tss)
    {
        GDTEntry entry;

        entry.type = GDTEntryType.TSS;

        // Set limit
        entry.data1 = 0x67;

        // Set base bytes 1, 2, and 3
        entry.data1 |= (tss << 16) & 0xFFFFFF0000L;

        // Set base byte 4
        entry.data1 |= (tss << 32) & 0xFF00000000000000L;

        // Set P, DPL, and type
        entry.data1 |= 0x0000890000000000L;

        entry.data2 = 0;
        entry.data2 = (tss >> 32) & 0xFFFFFFFFL;

        return entry;
    }

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

    ubyte index;
    ubyte offset;

    void init()
    {
        index = 0;
        offset = 0;
    }

    /**
     * Adds an entry to the next available spot in the GDT, and returns the GDT selector index
     */
    ubyte addEntry(GDTEntry e)
    {
        ubyte ret = offset;

        entries[index] = e.data1;

        if(e.type == GDTEntryType.TSS)
        {
            entries[index+1] = e.data2;
            index++;
            offset += 8;
        }
        index++;
        offset += 8;

        return ret;
    }

    void install()
    {
        gdtp.limit = (index + 1) * ulong.sizeof - 1;
        gdtp.address = cast(ulong)(&(entries[0]));

        asm
        {
            "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
        }
    }
}

struct GDTPtr
{
    align(1):
    ushort limit;
    ulong address;
}
