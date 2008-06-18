/**
 * Core components of the kernel's D runtime environment
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.heap;

PhysicalAllocator phys;
AddressSpace addr;
HeapAllocator heap;
