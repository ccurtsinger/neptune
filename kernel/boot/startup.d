/**
 * 62 bit Kernel Startup Code
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module kernel.boot.startup;

import modinit;

import std.stdio;
import std.string;
import std.context;

import util.arch.arch;
import util.arch.cpu;
import util.arch.apic;
import util.arch.descriptor;
import util.arch.gdt;
import util.arch.idt;
import util.arch.tss;
import util.arch.paging;

import util.spec.elf64;

import kernel.core.env;
import kernel.core.interrupt;
import kernel.dev.screen;
import kernel.dev.kb;
import kernel.dev.timer;
import kernel.task.procallocator;
import kernel.task.process;
import kernel.mem.watermark;

extern(C) void _startup(ulong loader, ulong* isrtable)
{
    // Set the global loader data pointer
    loaderData = cast(LoaderData*)ptov(loader);
    
    // Set up basic runtime and hardware structures
    memory_setup();
    interrupt_setup(isrtable);
    
    // Set a page fault handler
    localscope.setHandler(14, &pagefault_handler);
    
    // Initialize the GDT
    gdt_setup();
    
    // Initialize the CPU Local APIC
    cpu.apic = APIC();
    
    // Turn on interrupts to catch page faults, GP faults, etc...
    cpu.enableInterrupts();
    
    // Initialize the screen
    screen = new Screen(0xFFFF8300000B8000);
    
    screen.clear();
    stdout = screen;
    
    // Run module constructors and unit tests
    _moduleCtor();
    _moduleUnitTests();
    
    // Initialize the keyboard device
    kb.init(33);
    
    // Set the current processor with ID 0
    local = new Processor(0);
    
    // Initialize the processor allocator and add the current processor to its pool
    procalloc = new ProcessorAllocator();
    procalloc.add(local);
    
    // Initialize the timer device
    timer = new Timer(127);
    
    Elf64Header* elf;
    Elf64Header* exec;
    Elf64Header* lib;
    
    // Load modules passed from the loader as processes
    foreach(i, mod; loaderData.modules[0..loaderData.numModules])
    {
        writefln("module: %s", ctodstr(mod.name));
        
        elf = cast(Elf64Header*)mod.base;
        
        Process p = new Process(i, elf);
    }
 
    // Start the APIC timer on the same interrupt as the previously initialized timer device
    cpu.apic.setTimer(127, true, 10);
    
    // Idle until a task switch is performed
    for(;;){}
}

public void gdt_setup()
{
    cpu.gdt.init(_d_malloc(ulong.sizeof*256));
    
    NullDescriptor* n = cpu.gdt.getEntry!(NullDescriptor);
    *n = NullDescriptor();
    
    Descriptor* kc = cpu.gdt.getEntry!(Descriptor);
    *kc = Descriptor(true);
    kc.base = 0;
    kc.limit = 0xFFFFFF;
    kc.conforming = false;
    kc.privilege = 0;
    kc.present = true;
    kc.longmode = true;
    kc.operand = false;
    
    Descriptor* kd = cpu.gdt.getEntry!(Descriptor);
    *kd = Descriptor(false);
    kd.privilege = 0;
    kd.writable = true;
    kd.present = true;
    
    Descriptor* uc = cpu.gdt.getEntry!(Descriptor);
    *uc = Descriptor(true);
    uc.base = 0;
    uc.limit = 0xFFFFFF;
    uc.conforming = false;
    uc.privilege = 3;
    uc.present = true;
    uc.longmode = true;
    uc.operand = false;
    
    Descriptor* ud = cpu.gdt.getEntry!(Descriptor);
    *ud = Descriptor(false);
    ud.privilege = 3;
    ud.writable = true;
    ud.present = true;
    
    cpu.tss.init();
    
    cpu.tss.selector = cpu.gdt.getSelector();
  
    SystemDescriptor* t = cpu.gdt.getEntry!(SystemDescriptor);
    *t = SystemDescriptor();
    t.base = cpu.tss.address;
    t.limit = 0x68;
    t.type = DescriptorType.TSS;
    t.privilege = 0;
    t.present = true;
    t.granularity = false;
   
    cpu.tss.rsp0 = 0xFFFF81FFFFFFFFF0;
    
    cpu.gdt.install();
    
    cpu.tss.install();
}

public void interrupt_setup(ulong* isrtable)
{
    cpu.idt.init(0xFFFD);
    localscope.init();
    
    for(size_t i=0; i<256; i++)
    {
        GateDescriptor* d = cpu.idt[i];
       
        *d = GateDescriptor();
     
        d.target = isrtable[i];
        d.selector = 0x08;
        d.type = DescriptorType.INTERRUPT;
        d.stack = 0;
        d.privilege = 0;
        d.present = true;
        
        /*if(i == 127)
        {
            d.privilege = 3;
        }*/
    }
    
    cpu.idt.install();
}

public void memory_setup()
{    
    physical.init();
    
    foreach(region; loaderData.memoryRegions[0..loaderData.numMemoryRegions])
    {
        if(region.type == 1)
        {
            physical.add(region.base, region.size);
        }
    }

    foreach(used_region; loaderData.usedRegions[0..loaderData.numUsedRegions])
    {
        physical.remove(used_region.base, used_region.size);
    }
    
    cpu.pagetable = cast(PageTable*)ptov(loaderData.L4);
    
    Page* p = (*cpu.pagetable)[0xFFFF81FFFFFFF000];
    p.address = _d_palloc();
    p.writable = true;
    p.present = true;
    p.user = true;
    p.invalidate();
    
    p = (*cpu.pagetable)[0xFFFF81FFFFFFE000];
    p.address = _d_palloc();
    p.writable = true;
    p.present = true;
    p.user = true;
    p.invalidate();
    
    heap.init(cpu.pagetable, 0xFFFF820000000000);
    //heap = TreeAllocator(0xFFFF820000000000);
}

public bool pagefault_handler(Context* context)
{
    ulong addr = cpu.cr2;
    
    if(addr >= LINEAR_MEM_BASE && addr < LINEAR_MEM_BASE + PHYSICAL_MEM_LIMIT)
    {
        // Demand page memory in the linear-mapped region
        Page* p = (*cpu.pagetable)[addr];
        p.address = addr - LINEAR_MEM_BASE;
        p.writable = true;
        p.present = true;
        p.user = false;
        
        return true;
    }
    else if(addr >= cast(ulong)heap.start && addr <= cast(ulong)heap.end + FRAME_SIZE)
    {
        // Demand page the kernel heap
        Page* p = (*cpu.pagetable)[addr];
        p.address = _d_palloc();
        p.writable = true;
        p.present = true;
        p.user = false;
        
        return true;
    }
    else
    {
        // If the fault occurred on a page read violation
        if(context.error == 0x5)
        {
            // Emulate a function call across privilege levels
            if(addr == cast(ulong)&test_syscall)
            {
                context.rax = test_syscall(context.rdi);
                
                // Pop off the return address from the caller's stack
                context.rip = *(cast(ulong*)context.rsp);
                context.rsp += ulong.sizeof;
                
                return true;
            }
            else if(addr == cast(ulong)&syscall_1)
            {
                context.rax = syscall_1();
                
                // Pop off the return address from the caller's stack
                context.rip = *(cast(ulong*)context.rsp);
                context.rsp += ulong.sizeof;
                
                return true;
            }
            if(addr == cast(ulong)&syscall_2)
            {
                context.rax = syscall_2();
                
                // Pop off the return address from the caller's stack
                context.rip = *(cast(ulong*)context.rsp);
                context.rsp += ulong.sizeof;
                
                return true;
            }
            else if(addr == cast(ulong)&Elf64Header.runtimeLink)
            {
                Elf64Header* elf = (cast(Elf64Header**)context.rsp)[0];
                size_t plt_index = (cast(ulong*)context.rsp)[1];
                
                // remove GOT[1] and PLT index from stack
                context.rsp += ulong.sizeof * 2;
                
                context.rip = elf.runtimeLink(plt_index);
                
                return true;
            }
        }
        
        writefln("Unhandled page fault at address %p", addr);
        writefln("Error code %#x", context.error);
        writefln("%%rip: %p", context.rip);
        
        //heap.debugDump();
        
        version(unwind)
        {
            writefln("%p: %s", context.rip, getSymbol(context.rip));
            stackUnwind(cast(ulong*)context.rsp, cast(ulong*)context.rbp);
        }
        
        for(;;){}
    }
    
    return false;
}
