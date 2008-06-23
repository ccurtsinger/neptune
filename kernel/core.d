/**
 * Core components of the kernel's D runtime environment
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.heap;

import kernel.event;

PhysicalAllocator phys;
AddressSpace addr;
HeapAllocator heap;

EventDomain root;

extern(C) size_t palloc()
{
    return phys.allocate();
}

extern(C) void pfree(size_t p)
{
    phys.free(p);
}
