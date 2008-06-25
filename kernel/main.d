/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.core;
import kernel.event;
import kernel.spec.multiboot;
import kernel.spec.elf;

import kernel.arch.setup;
import kernel.arch.paging;
import kernel.arch.constants;
import kernel.arch.common;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.heap;

import std.stdio;
import std.string;

extern(C) void _main(MultibootInfo* multiboot, uint magic)
{
    PageTable* pagetable = arch_init();
    
    // Initialize the physical memory allocator
    p_init();
    
    if(p_state(0xb8000))
        writefln("0xb8000 is free");
    
    // Free memory from the multiboot memory map
    foreach(mem; multiboot.getMemoryMap())
    {
        // If memory region is available
        if(mem.type == 1)
        {
            // Determine the offset into a page frame of the base
            size_t offset = mem.base % FRAME_SIZE;
            
            // If the boundary isn't page-aligned, bump up to the next page
            if(offset != 0)
                offset = FRAME_SIZE - offset;
            
            // Loop over all complete pages in the set
            for(size_t i=offset; i+FRAME_SIZE <= mem.size; i+=FRAME_SIZE)
            {
                p_free(mem.base + i);
            }
        }
    }
    
    // Read ELF section headers from the multiboot structure
    ElfSectionHeader[] sections = multiboot.getElfSectionHeaders();
    
    // Track the highest section upper-boundary
    size_t kernel_top = 0;
    
    foreach(i, s; sections)
    {
        if(s.getOffset() + s.getSize() > kernel_top)
            kernel_top = s.getOffset() + s.getSize();
    }

    // Compute the top of the kernel binary
    kernel_top += KERNEL_PHYSICAL_ENTRY;
    
    // Find the bottom of the page containing the start of the kernel binary
    size_t kernel_base = KERNEL_PHYSICAL_ENTRY - (KERNEL_PHYSICAL_ENTRY % FRAME_SIZE);
    
    // Mark all memory used by the kernel binary as occupied
    for(size_t i=kernel_base; i<kernel_top; i+=FRAME_SIZE)
    {
        p_set(i);
    }

    // Initialize the base address space (kernel_top is a physical address, so it works as a size above KERNEL_VIRTUAL_BASE)
    addr = AddressSpace(pagetable, 0, 0, kernel_top);
    
    // Initialize the kernel heap
    m_init(&addr, ZoneType.KERNEL_HEAP);    
    
    foreach(mod; multiboot.getModules())
    {
        ElfHeader* elf = cast(ElfHeader*)mod.getData();
        
        if(elf.valid())
        {
            writefln("Loaded ELF module '%s'", mod.getString());
            
            // Mark physical memory used by modules as used
            size_t base = mod.getBase();
            size_t top = base + mod.getSize();
            
            base -= base % FRAME_SIZE;
            size_t offset = top % FRAME_SIZE;
            
            if(offset != 0)
                top += FRAME_SIZE - offset;
            
            for(size_t i=base; i<top; i+=FRAME_SIZE)
            {
                p_set(i);
            }
            
            // Create a process for this module
            proc = Process(cast(ElfHeader*)(cast(size_t)elf + KERNEL_VIRTUAL_BASE));
        }
    }
    
    arch_setup();
    
    enable_interrupts();
    
    for(;;){}
}

struct Process
{
    AddressSpace addr;
    size_t pagetable;
    size_t k_stack;
    Context context;
    
    public static Process opCall(ElfHeader* elf)
    {
        Process p;
        
        PageTable* pagetable = get_page_table();
        size_t pagetable_phys = pagetable.lookup(pagetable);
        
        PageTable* new_pagetable = pagetable.clone();
        p.pagetable = pagetable.lookup(new_pagetable); 
        
        size_t elf_base = size_t.max;
        size_t elf_top = 0;
        
        foreach(h; elf.getProgramHeaders())
        {
            if(h.getVirtualAddress() < elf_base)
                elf_base = h.getVirtualAddress();
                
            if(h.getMemorySize() + h.getVirtualAddress() > elf_top)
                elf_top = h.getMemorySize() + h.getVirtualAddress();
        }

        writefln("Elf binary maps in from %p to %p", elf_base, elf_top);
        
        // Pass a zero kernel size, since this address space will never be used to allocate on the kernel heap
        p.addr = AddressSpace(new_pagetable, elf_base, elf_top - elf_base, 0);
        
        writefln("pagetable: %p (%p)", p.pagetable, new_pagetable);
        
        load_page_table(p.pagetable);
        
        auto binary = p.addr.allocate(ZoneType.BINARY, elf_top - elf_base);
        auto stack = p.addr.allocate(ZoneType.STACK, FRAME_SIZE);
        auto kernel_stack = p.addr.allocate(ZoneType.KERNEL_STACK, FRAME_SIZE);
        
        p.k_stack = kernel_stack.top - size_t.sizeof;
        
        foreach(h; elf.getProgramHeaders())
        {
            ubyte[] data = h.getData(elf);
            
            for(size_t i=0; i<data.length; i+=FRAME_SIZE)
            {
                assert(p.addr.map(h.getVirtualAddress() + i, new_pagetable.lookup(data.ptr + i), Permission("r-x"), Permission("rwx"), false, false));
            }
        }

        assert(p.addr.map(stack.base, p_alloc(), Permission("rw-"), Permission("rw-"), false, false));
        
        assert(p.addr.map(kernel_stack.base, p_alloc(), Permission("---"), Permission("rw-"), false, false));
        
        p.context.eip = cast(size_t)elf.getEntry();
        p.context.cs = GDTSelector.USER_CODE | 0x3;
        p.context.ss = GDTSelector.USER_DATA | 0x3;
        p.context.flags = 0x202;
        
        p.context.esp = stack.top - 2*size_t.sizeof;
        p.context.ebp = stack.top - 1*size_t.sizeof;
        
        writefln("%#x %#x", 4*(cast(size_t)elf.getEntry() >> 22), 4*((cast(size_t)elf.getEntry() >> 12)&0x3ff));

        load_page_table(pagetable_phys);
        
        return p;
    }
}

Process proc;
Process* current = null;

extern(C) void task_switch(Context* context)
{
    if(current is null)
    {
        load_page_table(proc.pagetable);
        set_kernel_entry_stack(proc.k_stack);
        *context = proc.context;
        current = &proc;
        //for(;;){}
    }
}
