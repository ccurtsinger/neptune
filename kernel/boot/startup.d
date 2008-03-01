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

import arch.x86_64.arch;
import arch.x86_64.cpu;
import arch.x86_64.apic;
import arch.x86_64.descriptor;
import arch.x86_64.gdt;
import arch.x86_64.idt;
import arch.x86_64.tss;
import arch.x86_64.paging;

import spec.elf64;

import kernel.core.env;
import kernel.core.interrupt;
import kernel.dev.screen;
import kernel.dev.kb;
import kernel.dev.timer;
import kernel.task.scheduler;
import kernel.task.process;
import kernel.task.thread;
import kernel.mem.tree;

extern(C) void _startup(ulong loader, ulong* isrtable)
{
    // Set the global loader data pointer
    loaderData = cast(LoaderData*)ptov(loader);
    
    // Set up basic runtime and hardware structures
    gdt_setup();
    interrupt_setup(isrtable);
    memory_setup();
    
    // Initialize the CPU Local APIC
    cpu.apic = APIC();
    
    // Initialize the screen
    screen = cast(Screen*)0xFFFF8300000B8000;
    screen.clear();
    
    // Set a page fault handler
    localscope.setHandler(14, &pagefault_handler);
    
    // Run module constructors and unit tests
    _moduleCtor();
    _moduleUnitTests();
    
    // Initialize the keyboard device
    kb.init(33);
    
    // Set up a system call handler
    localscope.setHandler(128, &syscall_handler);
    
    // Initialize the scheduler
    scheduler = new Scheduler();
    
    // Initialize the timer device
    timer = new Timer(127);
    
    // Load modules passed from the loader as processes
    foreach(mod; loaderData.modules[0..loaderData.numModules])
    {
        writefln("module: %s", ctodstr(mod.name));
        
        Elf64Header* elf = cast(Elf64Header*)mod.base;
        Process p = new Process(elf);
        p.start();
    }
    
    // Start the APIC timer on the same interrupt as the previously initialized timer device
    cpu.apic.setTimer(127, true, 10);

    // Enable interrupts and idle until a task switch is performed
    cpu.enableInterrupts();
    
    for(;;){}
}

public void gdt_setup()
{
    cpu.gdt.init();
    
    NullDescriptor* n = cpu.gdt.getEntry!(NullDescriptor);
    *n = NullDescriptor();
    
    CodeDescriptor* kc = cpu.gdt.getEntry!(CodeDescriptor);
    *kc = CodeDescriptor();
    kc.base = 0;
    kc.limit = 0xFFFFFF;
    kc.conforming = false;
    kc.privilege = 0;
    kc.present = true;
    kc.longmode = true;
    kc.operand = false;
    
    DataDescriptor* kd = cpu.gdt.getEntry!(DataDescriptor);
    *kd = DataDescriptor();
    kd.privilege = 0;
    kd.writable = true;
    kd.present = true;
    
    CodeDescriptor* uc = cpu.gdt.getEntry!(CodeDescriptor);
    *uc = CodeDescriptor();
    uc.base = 0;
    uc.limit = 0xFFFFFF;
    uc.conforming = false;
    uc.privilege = 3;
    uc.present = true;
    uc.longmode = true;
    uc.operand = false;
    
    DataDescriptor* ud = cpu.gdt.getEntry!(DataDescriptor);
    *ud = DataDescriptor();
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
    cpu.tss.rsp1 = 0xFFFF81FFFFFFFFF0;
    cpu.tss.rsp2 = 0xFFFF81FFFFFFFFF0;
   
    cpu.tss.ist1 = 0xFFFF81FFFFFFEFF0;
    
    cpu.gdt.install();
    
    cpu.tss.install();
}

public void interrupt_setup(ulong* isrtable)
{
    cpu.idt.init(0xFFFF);
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
        
        if(i == 32 || i == 128)
        {
            d.privilege = 3;
        }
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
    
    //heap.init(cpu.pagetable, 0xFFFF820000000000);
    heap = TreeAllocator(0xFFFF820000000000);
}

public bool pagefault_handler(InterruptStack* context)
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
        writefln("Unhandled page fault at address %016#X", addr);
        
        heap.debugDump();
        
        version(unwind)
        {
            writefln("%016#X: %s", context.rip, getSymbol(context.rip));
            stackUnwind(cast(ulong*)context.rsp, cast(ulong*)context.rbp);
        }
        
        for(;;){}
    }
    
    return false;
}

public bool syscall_handler(InterruptStack* context)
{
    // Show heap information periodically
    if(context.rax % 20 == 0)
    {
        heap.debugDump();
        for(size_t i=0; i<10000000; i++){}
    }
    
    writefln("Process %u", context.rax);
    
    timer.wait(context.rax, context);
        
    return true;
}
