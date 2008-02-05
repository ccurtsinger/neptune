/**
 * Architecture and implementation specific utilities and constants
 *
 * Authors: Charlie Curtsinger
 * Date: January 15, 2008
 * Version 0.2a
 */

module kernel.arch.Arch;

import std.type;

/// Type for interrupt service routines
alias void function() isr_t;

/// Base address for linear-mapped physical memory
const paddr_t LINEAR_MEM_BASE = 0xFFFF830000000000;

/// Page (frame) size
const size_t FRAME_SIZE = 0x1000;

/**
 * Convert a physical address to an accessible virtual address
 *
 * Params:
 *  address = Physical address
 *
 * Returns: Virtual address in the linear-mapped range that points
 *  to the provided physical address
 */
vaddr_t ptov(paddr_t address)
{
    return cast(vaddr_t)(address + LINEAR_MEM_BASE);
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
paddr_t vtop(vaddr_t address)
{
    return cast(paddr_t)address - LINEAR_MEM_BASE;
}
