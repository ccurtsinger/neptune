/**
 * 64 bit Kernel Startup Code
 *
 * Copyright: 2008 The Neptune Project
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

import kernel.task.scheduler;
import kernel.task.process;

import kernel.mem.physical : p_init, p_set;
import kernel.mem.heap : m_init, m_base, m_limit;

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
    CPU.apic = APIC();
    
    // Turn on interrupts to catch page faults, GP faults, etc...
    CPU.enableInterrupts();
    
    // Initialize the screen
    screen = new Screen(SCREEN_MEM);
    
    screen.clear();
    stdout = screen;
    
    // Run module constructors and unit tests
    writeln("Running module constructors");
    _moduleCtor();
    
    debug
    {
        writeln("Running module unit tests");
        _moduleUnitTests();
    }
    
    // Initialize the keyboard device
    kb.init(33);
    
    // Initialize the processor allocator and add the current processor to its pool
    scheduler = new Scheduler();
    
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
        
        scheduler.add(p);
    }
    
    localscope.setHandler(128, &syscall);
    
    CPU.idt[14].stack = 1;
 
    // Start the APIC timer on the same interrupt as the previously initialized timer device
    CPU.apic.setTimer(127, true, 10);
    
    // Idle until a task switch is performed
    for(;;){}
}

public bool syscall(Context* context)
{
    writeln("syscall!");
    
    for(size_t i=0; i<10000000; i++)
    {
        asm{"pause";}
    }
    
    return true;
}

public void gdt_setup()
{
    CPU.gdt.init(m_alloc(ulong.sizeof*256));
    
    NullDescriptor* n = CPU.gdt.getEntry!(NullDescriptor);
    *n = NullDescriptor();
    
    Descriptor* kc = CPU.gdt.getEntry!(Descriptor);
    *kc = Descriptor(true);
    kc.conforming = false;
    kc.privilege = 0;
    kc.present = true;
    kc.longmode = true;
    kc.operand = false;
    
    Descriptor* kd = CPU.gdt.getEntry!(Descriptor);
    *kd = Descriptor(false);
    kd.privilege = 0;
    kd.writable = true;
    kd.present = true;
    
    Descriptor* uc = CPU.gdt.getEntry!(Descriptor);
    *uc = Descriptor(true);
    uc.conforming = false;
    uc.privilege = 3;
    uc.present = true;
    uc.longmode = true;
    uc.operand = false;
    
    Descriptor* ud = CPU.gdt.getEntry!(Descriptor);
    *ud = Descriptor(false);
    ud.privilege = 3;
    ud.writable = true;
    ud.present = true;
    
    CPU.tss.init();
    
    CPU.tss.selector = CPU.gdt.getSelector();
  
    SystemDescriptor* t = CPU.gdt.getEntry!(SystemDescriptor);
    *t = SystemDescriptor();
    t.base = CPU.tss.address;
    t.limit = 0x68;
    t.type = DescriptorType.TSS;
    t.privilege = 0;
    t.present = true;
    t.granularity = false;
    
    CPU.gdt.install();
    
    CPU.tss.ist[1] = 0xFFFF85FFFFFFFFF0;
    
    CPU.tss.install();
}

public void interrupt_setup(ulong* isrtable)
{
    CPU.idt.init(0xFFFD);
    localscope.init();
    
    for(size_t i=0; i<256; i++)
    {
        GateDescriptor* d = CPU.idt[i];
       
        *d = GateDescriptor();
     
        d.target = isrtable[i];
        d.selector = 0x08;
        d.type = DescriptorType.INTERRUPT;
        d.stack = 0;
        d.privilege = 0;
        d.present = true;
        
        if(i == 128)
            d.privilege = 3;
    }
    
    CPU.idt.install();
}

public void memory_setup()
{    
    p_init();
    
    foreach(region; loaderData.memoryRegions[0..loaderData.numMemoryRegions])
    {
        if(region.type == 1)
        {
            for(size_t i = region.base; i < region.base + region.size; i += FRAME_SIZE)
            {
                p_free(i);
            }
        }
    }

    foreach(used_region; loaderData.usedRegions[0..loaderData.numUsedRegions])
    {
        for(size_t i = used_region.base; i < used_region.base + used_region.size; i += FRAME_SIZE)
        {
            p_set(i);
        }
    }
    
    CPU.pagetable = cast(PageTable*)ptov(loaderData.L4);
    
    Page* p = (*CPU.pagetable)[0xFFFF85FFFFFFF000];
    p.address = p_alloc();
    p.writable = true;
    p.present = true;
    p.user = false;
    
    m_init(CPU.pagetable);
}

public bool pagefault_handler(Context* context)
{
    ulong addr = CPU.cr2;
    
    if(addr >= LINEAR_MEM.base && addr < LINEAR_MEM.top)
    {
        // Demand page memory in the linear-mapped region
        Page* p = (*CPU.pagetable)[addr];
        p.address = addr - LINEAR_MEM.base;
        p.writable = true;
        p.present = true;
        p.user = false;
        
        return true;
    }
    else if(addr >= m_base() && addr < m_limit())
    {
        // Demand page the kernel heap
        Page* p = (*CPU.pagetable)[addr];
        p.address = p_alloc();
        p.writable = true;
        p.present = true;
        p.user = false;
        
        return true;
    }
    else if(addr >= scheduler.current.thread.stack.base && addr < scheduler.current.thread.stack.top)
    {
        Page* stack_page = (*CPU.pagetable)[addr];
        stack_page.address = p_alloc();
        stack_page.writable = true;
        stack_page.present = true;
        stack_page.user = true;
        
        return true;
    }
    else if(addr >= scheduler.current.thread.kernel_stack.base && addr < scheduler.current.thread.kernel_stack.top)
    {
        Page* p = (*CPU.pagetable)[addr];
        p.address = p_alloc();
        p.writable = true;
        p.present = true;
        p.user = true;
        
        return true;
    }
        
    writefln("Unhandled page fault at address %p", addr);
    writefln("Error code %#x", context.error);
    writefln("%%rip: %p", context.rip);
    for(;;){}
    version(unwind)
    {
        writefln("%p: %s", context.rip, getSymbol(context.rip));
        stackUnwind(cast(ulong*)context.rsp, cast(ulong*)context.rbp);
    }
    
    for(;;){}
    
    return false;
}
