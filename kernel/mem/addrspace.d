/**
 * Abstraction for an address space
 *
 * Copyright: 2008 The Neptune Project
 */
 
module kernel.mem.addrspace;

import kernel.arch.paging;
import kernel.arch.constants;

import kernel.mem.range;

import std.bitarray;

enum ZoneType
{
    INFO,
    BINARY,
    HEAP,
    STACK,
    DYNAMIC,
    KERNEL_BINARY,
    KERNEL_HEAP,
    KERNEL_STACK,
    KERNEL_DYNAMIC
}

struct Zone
{
    MemoryRange range;
    bool increasing;
    
    public static Zone opCall(MemoryRange range, bool increasing = true)
    {
        Zone z;
        z.range = range;
        z.increasing = increasing;
        return z;
    }
}

struct AddressSpace
{
    private PageTable* pagetable;
    
    private Zone[9] zones;
    
    public static AddressSpace opCall(PageTable* pagetable, size_t binary_size, size_t kernel_size)
    {
        // Round the binary size off to a multiple of FRAME_SIZE
        size_t r = binary_size % FRAME_SIZE;
        
        if(r != 0)
            binary_size += FRAME_SIZE - r;
            
        r = kernel_size % FRAME_SIZE;
        
        if(r != 0)
            kernel_size += FRAME_SIZE - r;
        
        AddressSpace a;
        
        a.pagetable = pagetable;
        
        // Reserve a page for the process info structure
        a.zones[ZoneType.INFO] = Zone(MemoryRange(FRAME_SIZE, FRAME_SIZE));
        
        // Reserve memory for the process binary image
        a.zones[ZoneType.BINARY] = Zone(MemoryRange(2*FRAME_SIZE, binary_size));
        
        // Reserve an upward-growing user heap
        a.zones[ZoneType.HEAP] = Zone(MemoryRange(2*FRAME_SIZE + binary_size, STACK_TOP - (2*FRAME_SIZE + binary_size)));
        
        // Reserve a downward-growing user stack
        a.zones[ZoneType.STACK] = Zone(MemoryRange(2*FRAME_SIZE + binary_size, STACK_TOP - (2*FRAME_SIZE + binary_size)), false);
        
        // Reserve fixed-size dynamic memory range
        a.zones[ZoneType.DYNAMIC] = Zone(MemoryRange(STACK_TOP, USER_VIRTUAL_TOP - STACK_TOP));
        
        // Reserve kernel memory ranes
        a.zones[ZoneType.KERNEL_BINARY] = Zone(MemoryRange(KERNEL_VIRTUAL_BASE, kernel_size));
        a.zones[ZoneType.KERNEL_HEAP] = Zone(MemoryRange(KERNEL_VIRTUAL_BASE + kernel_size, KERNEL_STACK_TOP - (KERNEL_VIRTUAL_BASE + kernel_size)));
        a.zones[ZoneType.KERNEL_STACK] = Zone(MemoryRange(KERNEL_VIRTUAL_BASE + kernel_size, KERNEL_STACK_TOP - (KERNEL_VIRTUAL_BASE + kernel_size)), false);
        a.zones[ZoneType.KERNEL_DYNAMIC] = Zone(MemoryRange(KERNEL_STACK_TOP, VIRTUAL_MEMORY_MAX - KERNEL_STACK_TOP + 1));
        
        // Mark kernel binary pages as occupied
        a.allocate(ZoneType.KERNEL_BINARY, kernel_size);
        
        return a;
    }
    
    public MemoryRange allocate(ZoneType type, size_t size)
    {
        MemoryRange r = pagetable.allocate(size, zones[type].range, zones[type].increasing);
        
        assert(r.size >= size, "out of memory in the requested zone");
        
        return r;
    }
    
    public bool map(size_t v_addr, size_t p_addr, Permission user, Permission superuser, bool global, bool locked)
    {
        return pagetable.map(v_addr, p_addr, user, superuser, global, locked);
    }
}
