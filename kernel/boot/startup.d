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

import util.spec.elf64;

import kernel.core.env;
import kernel.core.arch;
import kernel.core.mem;
import kernel.core.interrupt;
import kernel.core.event;

import util.arch.cpu;
import util.arch.paging;

import kernel.dev.screen;
import kernel.dev.kb;
import kernel.dev.timer;

import kernel.task.scheduler;
import kernel.task.process;

extern(C) void _startup(ulong loader)
{
    // Set the global loader data pointer
    loaderData = cast(LoaderData*)ptov(loader);
    
    // Set up basic runtime and hardware structures
    memory_setup();
    
    arch_setup();
    
    // Set a page fault handler
    localscope.setHandler(14, &pagefault_handler);
    
    // Initialize the screen
    screen = new Screen(SCREEN_MEM);
    
    screen.clear();
    stdout = screen;
    
    // Turn on interrupts to catch page faults, GP faults, etc...
    CPU.enableInterrupts();
    
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
    
    root = EventDomain();
    
    root.addHandler("test.event", EventHandler(0, &test_event_handler));
    
    root.raiseEvent("test.event");
    root.raiseEvent("test.event.a");
    root.raiseEvent("test");
    
    for(;;){}
 
    // Start the APIC timer on the same interrupt as the previously initialized timer device
    CPU.apic.setTimer(127, true, 10);
    
    // Idle until a task switch is performed
    for(;;){}
}

void test_event_handler(char[] domain)
{
    writefln("Fired event %s", domain);
}

extern(C) void test_syscall()
{
    writeln("syscall!");
    
    for(size_t i=0; i<10000000; i++)
    {
        asm{"pause";}
    }
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

    version(unwind)
    {
        writefln("%p: %s", context.rip, getSymbol(context.rip));
        stackUnwind(cast(ulong*)context.rsp, cast(ulong*)context.rbp);
    }
    
    for(;;){}
    
    return false;
}
