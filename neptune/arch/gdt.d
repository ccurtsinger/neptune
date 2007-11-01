/**
 * GDT Abstraction and Utilities
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module neptune.arch.gdt;

import neptune.arch.tss;

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

struct GDTPtr
{
    align(1):
    ushort limit;
    void* address;
}

/**
 * Struct used to perform bit-twiddling operations for entries into the GDT
 */
struct GDTEntry
{
	/// First eight byte section of the entry
    ulong data1;
    
    /// Second eight byte section (not used by all entry types)
    ulong data2;
    
    /// Entry type
    GDTEntryType type;

    /**
     * Create a TSS Descriptor Entry for the GDT
     *
	 * Params:
     * 	tss = Address of the TSS
     *
     * Returns: The new GDT entry
     */
    static GDTEntry opCall(void* tss)
    {
        GDTEntry entry;

        entry.type = GDTEntryType.TSS;

        // Set limit (this will change when port restrictions are supported)
        entry.data1 = 0x67;

        // Set base bytes 1, 2, and 3
        entry.data1 |= (cast(ulong)tss << 16) & 0xFFFFFF0000L;

        // Set base byte 4
        entry.data1 |= (cast(ulong)tss << 32) & 0xFF00000000000000L;

        // Set P, DPL, and type
        entry.data1 |= 0x0000890000000000L;

        entry.data2 = 0;
        entry.data2 = (cast(ulong)tss >> 32) & 0xFFFFFFFFL;

        return entry;
    }

    /**
     * Create a code/data segment entry for the GDT
     *
     * Params:
     *  t = Type of entry to create
     *  p = Permission level for the segment
     *
     * Returns: The new GDT entry
     */
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

/**
 * Abstraction for the Global Descriptor Table
 */
struct GDT
{
	/// The actual GDT data
    ulong[256] entries;
    
    /// GDT pointer structure initialized and used only when loading the GDT with install()
    GDTPtr gdtp;

	/// The next available index in the GDT
    ubyte index;
    ubyte offset;

	/**
	 * Initialize the GDT
	 */
    void init()
    {
        index = 0;
    }

    /**
     * Adds an entry to the next available spot in the GDT, and returns the GDT selector index
     *
     * Params:
     *  e = Prepared GDT entry
     *
     * Returns: Selector index of the newly created entry
     */
    ubyte addEntry(GDTEntry e)
    {
        ubyte ret = index*8;

        entries[index] = e.data1;

        if(e.type == GDTEntryType.TSS)
        {
            entries[index+1] = e.data2;
            index++;
        }
        index++;

        return ret;
    }

	/**
	 * Loads the GDT
	 */
    void install()
    {
        gdtp.limit = (index + 1) * 8 - 1;
        gdtp.address = entries.ptr;

        asm
        {
            "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
        }
    }
}
