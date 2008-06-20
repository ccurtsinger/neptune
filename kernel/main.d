/**
 * Kernel Entry Point
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.main;

import kernel.core;
import kernel.spec.multiboot;
import kernel.arch.native;

import kernel.mem.physical;
import kernel.mem.addrspace;
import kernel.mem.heap;

import std.stdio;

extern(C) void _main(MultibootInfo* multiboot, uint magic)
{
    PageTable* pagetable = startup();
    
    // Initialize the physical memory allocator
    phys.init();
    
    size_t lost = 0;
    
    // Free memory from the multiboot memory map
    foreach(mem; multiboot.getMemoryMap())
    {
        // If memory region is available
        if(mem.type == 1)
        {
            // TODO: Determine if the page is occupied by the kernel binary, and if so, don't free it
            
            // Determine the offset into a page frame of the base
            size_t offset = mem.base % FRAME_SIZE;
            
            // If the boundary isn't page-aligned, bump up to the next page
            if(offset != 0)
                offset = FRAME_SIZE - offset;
            
            // Loop over all complete pages in the set
            for(size_t i=offset; i<=mem.size && i+FRAME_SIZE <= mem.size; i+=FRAME_SIZE)
            {
                phys.free(mem.base + i);
            }
        }
    }
    
    // Initialize the base address space
    addr = AddressSpace(pagetable, 0, FRAME_SIZE);
    
    // Initialize the kernel heap
    heap = HeapAllocator(&phys, &addr, ZoneType.KERNEL_HEAP);
    
    auto s = addr.allocate(ZoneType.KERNEL_STACK, FRAME_SIZE);
    addr.map(s.base, phys.allocate(), Permission("---"), Permission("rw-"), false, false);
    set_kernel_entry_stack(s.top - size_t.sizeof);
    
    set_interrupt_handler(128, &test_syscall);
    set_interrupt_handler(80, &entry);
    
    auto test = addr.allocate(ZoneType.BINARY, FRAME_SIZE);
    
    addr.map(test.base, phys.allocate(), Permission("rwx"), Permission("rwx"), false, false);
    
    byte* b = cast(byte*)test.base;
    
    b[0..80] = (cast(byte*)&usermode_test)[0..80];
    
    asm
    {
        "int $80" : : "b" test.base;
    }
    
    for(;;){}
}

bool entry(Context* context)
{
    auto stack = addr.allocate(ZoneType.STACK, FRAME_SIZE);
    
    addr.map(stack.base, phys.allocate(), Permission("rw-"), Permission("rw-"), false, false);
        
    context.eip = context.ebx;
    context.eax = context.ebx;
    context.esp = stack.top - size_t.sizeof;
    context.cs = SEL_USER_CODE | 3;
    context.ss = SEL_USER_DATA | 3;
    
    writefln("jumping to %p", context.eip);
    
    return true;
}

bool test_syscall(Context* context)
{
    writefln("here!");
   
    return false;
}

extern(C) void usermode_test()
{
    asm
    {
        "pop %%ebx";
        "incl %%edi";
        "int $128";
        "jmp %%eax";
    }
}
