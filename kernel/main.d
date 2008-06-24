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
            for(size_t i=offset; i<=mem.size && i+FRAME_SIZE <= mem.size; i+=FRAME_SIZE)
            {
                p_free(mem.base + i);
            }
        }
    }
    
    // Read ELF section headers from the multiboot structure
    ElfSectionHeader[] sections = multiboot.getElfSectionHeaders();
    
    // Track the highest section upper-boundary
    size_t max = 0;
    
    foreach(i, s; sections)
    {
        if(s.getOffset() + s.getSize() > max)
            max = s.getOffset() + s.getSize();
    }

    // Compute the top of the kernel binary
    max += KERNEL_PHYSICAL_ENTRY;
    
    // Find the bottom of the page containing the start of the kernel binary
    size_t base = KERNEL_PHYSICAL_ENTRY - (KERNEL_PHYSICAL_ENTRY % FRAME_SIZE);
    
    // Mark all memory used by the kernel binary as occupied
    for(size_t i=base; i<max; i+=FRAME_SIZE)
    {
        p_set(i);
    }
    
    /*ElfHeader* process_image;
    
    foreach(mod; multiboot.getModules())
    {
        writeln(mod.getString());
        ElfHeader* elf = cast(ElfHeader*)mod.getData();
        
        if(elf.valid())
        {
            writeln("valid!");
            process_image = elf;
        }
    }
    
    auto program_headers = process_image.getProgramHeaders();
    size_t total = 0;
    
    foreach(h; program_headers)
    {
        writefln("%s: %#x %#x", h.getTypeName(), h.getMemorySize(), h.getFileSize());
        total += h.getMemorySize();
    }
    
    writefln("Total Size of module: %#x", total);*/
    
    // Initialize the base address space (assume 4MB kernel)
    addr = AddressSpace(pagetable, 0, 0x400000);
    
    // Initialize the kernel heap
    m_init(&addr, ZoneType.KERNEL_HEAP);    
    arch_setup();
    
    enable_interrupts();
    
    for(;;){}
}
