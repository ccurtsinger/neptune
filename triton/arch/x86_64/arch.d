/**
 * Architecture and implementation-specific utilities and constants
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module arch.x86_64.arch;

/// Type for interrupt service routines
alias void function() isr_t;

/// Base address for linear-mapped physical memory
const ulong LINEAR_MEM_BASE = 0xFFFF830000000000;

/// Limit for physical addresses
const ulong PHYSICAL_MEM_LIMIT = (cast(ulong)1 << 40);

/// Page (frame) size
const ulong FRAME_SIZE = 0x1000;

/**
 * Convert a physical address to an accessible virtual address
 *
 * Params:
 *  address = Physical address
 *
 * Returns: Virtual address in the linear-mapped range that points
 *  to the provided physical address
 */
version(x86_64)
{
    void* ptov(ulong address)
    {
        return cast(void*)(address + LINEAR_MEM_BASE);
    }
}
else version(i586)
{
    void* ptov(ulong address)
    in
    {
        assert(address < uint.max, "Cannot reference memory above 32 bit addresses on i586 architecture");
    }
    body
    {
        return cast(void*)address;
    }
}

/**
 * Convert a virtual address in the linear-mapped range to its 
 * corresponding physical address.
 *
 * Params:
 *  address = Virtual address to convert
 *
 * Returns: Physical address pointed to by the given virtual address
 */
version(x86_64)
{
    ulong vtop(void* address)
    {
        return cast(ulong)address - LINEAR_MEM_BASE;
    }
}
else version(i586)
{
    size_t vtop(void* address)
    {
        return cast(size_t)address;
    }
}
else
{
    static assert(false, "Unsupported version");
}
