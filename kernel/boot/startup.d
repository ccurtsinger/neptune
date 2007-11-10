/**
 * D entry point for the Neptune Kernel
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.2a
 */

module kernel.boot.kernel;

import std.stdmem;
import std.modinit;
import std.stdlib;
import std.port;

import std.mem.AddressSpace;

import neptune.arch.gdt;
import neptune.arch.tss;
import neptune.arch.idt;
import neptune.arch.paging;

import kernel.kernel;
import kernel.dev.screen;
import kernel.dev.kb;
import kernel.mem.physical;
import kernel.mem.virtual;
import kernel.mem.dummy;
import kernel.mem.StackAllocator;
import kernel.task.Scheduler;
import kernel.task.Thread;

const ulong LINEAR_MEM_BASE = 0xFFFF830000000000;

/// GDT
GDT gdt;

/// TSS
TSS tss;

/// IDT
IDT idt;

/// Keyboard device
Keyboard kb;

/// Screen device
Screen screen;

Scheduler scheduler;

VirtualMemory v;

/**
 * Starting function for D
 *
 * Params:
 *  loader = Pointer to the loader data struct - contains memory information
 */
extern(C) void _main(LoaderData* loader)
{
	// Initialize important data structures
    mem_setup(loader);
    gdt_setup();
    tss_setup();
    idt_setup();

    // Install GDT, IDT, and TSS
    gdt.install();
    tss.install();
    idt.install();
    
    screen = new Screen();
    screen.clear();
    
    System.setOutput(screen);
    System.setError(screen);
    System.setInput(kb);

	// Run module constructors and unit tests
	_moduleCtor();
	_moduleUnitTests();
	
	main();
	
	System.output.write("Kernel exited").newline;
	
	ubyte good = 0x02;
    while ((good & 0x02) != 0)
        good = inp(0x64);
    outp(0x64, 0xFE);

	for(;;){}
}

/**
 * Set up the kernel's memory system
 *
 * Params:
 *  loader = pointer to the loader data struct containing memory information
 */
void mem_setup(LoaderData* loader)
{
    DummyAllocator dummyAllocator;
    PhysicalAllocator pmem;
    Heap heap;
    StackAllocator stack;
    
    AddressSpace mem;
    
    void* alloc = loader.tempData;

    mem = new(alloc) AddressSpace();
    alloc += System.pageSize;
    dummyAllocator = new(alloc) DummyAllocator();
    alloc += System.pageSize;
    dummyAllocator.add(alloc, loader.tempDataSize - System.pageSize);
    
    System.setMemory(mem);
    mem.setAllocator(dummyAllocator);
    
    pmem = new PhysicalAllocator();

    pmem.add(loader.lowerMemBase, loader.lowerMemSize);
    pmem.add(loader.upperMemBase, loader.usedMemBase - loader.upperMemBase);
    pmem.add(loader.usedMemBase + loader.usedMemSize, loader.upperMemSize - loader.usedMemBase - loader.usedMemSize + loader.upperMemBase);

    mem.setPhysicalAllocator(pmem);

    //v = new(alloc.ptr) VirtualMemory(loader.L4);
    v.init(loader.L4);

    // Map a 16k interrupt stack for IST1
    v.map(cast(void*)0x7FFFC000);
    v.map(cast(void*)0x7FFFD000);
    v.map(cast(void*)0x7FFFE000);
    v.map(cast(void*)0x7FFFF000);

    // Initialize the heap allocator object
    heap = new Heap(&v);
    
    mem.setAllocator(heap);
    
    stack = new StackAllocator(&v);
    
    mem.setStackAllocator(stack);
}

/**
 * Add necessary entries to the GDT
 */
void gdt_setup()
{
    gdt.init();

    // Create null descriptor in GDT
    gdt.addEntry(GDTEntry(GDTEntryType.NULL));

    // Create kernel code descriptor in GDT
    gdt.addEntry(GDTEntry(GDTEntryType.CODE, DPL.KERNEL));

    // Create kernel data descriptor in GDT
    gdt.addEntry(GDTEntry(GDTEntryType.DATA, DPL.KERNEL));

    // Create user code desciptor in GDT
    gdt.addEntry(GDTEntry(GDTEntryType.CODE, DPL.USER));

    // Create user data descriptor in GDT
    gdt.addEntry(GDTEntry(GDTEntryType.DATA, DPL.USER));

    // Create TSS Descriptor entry in GDT
    ushort tssSelector = gdt.addEntry(GDTEntry(&tss));

    tss.setSelector(tssSelector);
}

/**
 * Create and initialize a TSS with IST
 */
void tss_setup()
{
    tss.init();

    // Set the permission-level stacks
    tss.setRspEntry(0, cast(void*)0xFFFF810000000000);
    tss.setRspEntry(1, cast(void*)0xFFFF810000000000);
    tss.setRspEntry(2, cast(void*)0xFFFF810000000000);

    // Set IST entry
    tss.setIstEntry(0, cast(void*)0x7FFFFFF8);
}

/**
 * Set up an IDT and install handlers for keyboard an page fault
 */
void idt_setup()
{
	idt.init();

	// Install the page fault handler
	idt.setHandler(14, &pagefault_handler);

	// Initialize keyboard data and install the interrupt handler
	kb = new Keyboard();
    idt.setHandler(33, &kb.handler);
    
    KernelThread t = new KernelThread(1, 0);
    scheduler = new Scheduler(t);
    
    idt.setHandler(255, &scheduler.task_switcher);
    idt.setHandler(254, &scheduler.create_thread);
}

/**
 * Page fault handler - Attempts to map missing pages
 *
 * Params:
 *  p = ignored pointer (filler for the 'this' pointer)
 *  interrupt = interrupt number
 *  error = error code
 *  stack = pointer to context information
 */
void pagefault_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    ulong vAddr;
	asm
	{
	    "mov %%cr2, %[addr]" : [addr] "=a" vAddr;
    }

    System.output.writef("\nPage Fault: %#X", vAddr, "\nMapping...");

    if(v.map(cast(void*)vAddr))
    {
        System.output.write("done").newline;
    }
    else
    {
        System.output.write("failed").newline;
        System.output.writef("  %016#X", stack.rip).newline;
        for(;;){}
    }
}

extern(C)
{
    /**
     * Convert a physical address to a pointer into the linear-mapped virtual address range
     *
     * Params:
     *  pAddr = physical address to reference
     *
     * Returns: a pointer to memory that will allow read/write access to pAddr
     */
    void* ptov(ulong pAddr)
    {
        return cast(void*)(pAddr + LINEAR_MEM_BASE);
    }
}

/**
 * Data passed from the 32 bit loader
 */
struct LoaderData
{
    align(1):
    /// Physical address of the top-level page directory
	ulong L4;
	
	/// Base address of the used memory
	ulong usedMemBase;
	
	/// Size of the used memory
	ulong usedMemSize;
	
	/// Base address of lower memory
	ulong lowerMemBase;
	
	/// Size of lower memory
	ulong lowerMemSize;
	
	/// Base address of upper memory
	ulong upperMemBase;
	
	/// Size of upper memory
	ulong upperMemSize;
	
	ulong regions;
	
	ulong memInfo;
	
	void* tempData;
	
	size_t tempDataSize;
}
