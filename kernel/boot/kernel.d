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

import neptune.arch.gdt;
import neptune.arch.tss;
import neptune.arch.idt;
import neptune.arch.paging;
import neptune.mem.AddressSpace;

import kernel.dev.screen;
import kernel.dev.kb;
import kernel.mem.physical;
import kernel.mem.virtual;
import kernel.mem.dummy;
import kernel.task.Scheduler;
import kernel.task.Thread;

const ulong LINEAR_MEM_BASE = 0xFFFF830000000000;

DummyAllocator dummyAllocator;

PhysicalAllocator pmem;

/// GDT
GDT gdt;

/// TSS
TSS tss;

/// IDT
IDT idt;

/// Dynamic memory allocator (heap) for the kernel
Heap heap;

/// Keyboard device
Keyboard kb;

/// Screen device
Screen screen;

AddressSpace mem;

Scheduler scheduler;

/// Paging abstraction
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
    
    mem = new AddressSpace(&v);

    System.output.write("Hello Neptune!").newline;

    System.output.write("Memory Information:").newline;
    System.output.writef(" - Free: %016#X", pmem.getFreeSize).newline;
    System.output.writef(" - Allocated: %016#X", pmem.getAllocatedSize).newline;
	
	// Run module constructors and unit tests
	_moduleCtor();
	_moduleUnitTests();
	
	spawn_thread(mem.getStack(), &thread_function);
	spawn_thread(mem.getStack(), &thread_function);
	spawn_thread(mem.getStack(), &thread_function);
		
	while(true)
	{
		char[] line = System.input.readln(screen);
		System.output.write(line);
		delete line;
		System.output.writef("typing in thread %u", scheduler.getThreadID()).newline;
		yield();
	}
	
	for(;;){}
}

void thread_function()
{
    while(true)
    {
        System.output.writef("hello from thread %u", scheduler.getThreadID()).newline;
        yield();
    }
}

void yield()
{
    asm
    {
        "int $255";
    }
}

ulong spawn_thread(void* stack, void function() thread)
{
    ulong result;
    
    asm
    {
        "int $254" : "=a" result, "=c" thread : "b" stack, "c" thread;
    }
    
    if(result == 0)
    {
        thread();
        assert(false, "Unhandled thread termination");
    }
    
    return result;
}

/**
 * Set up the kernel's memory system
 *
 * Params:
 *  loader = pointer to the loader data struct containing memory information
 */
void mem_setup(LoaderData* loader)
{
    dummyAllocator = new(loader.tempData) DummyAllocator();
    dummyAllocator.add(loader.tempData + System.pageSize, loader.tempDataSize - System.pageSize);
    System.setAllocator(dummyAllocator);
    
    pmem = new PhysicalAllocator();

    pmem.add(loader.lowerMemBase, loader.lowerMemSize);
    pmem.add(loader.upperMemBase, loader.usedMemBase - loader.upperMemBase);
    pmem.add(loader.usedMemBase + loader.usedMemSize, loader.upperMemSize - loader.usedMemBase - loader.usedMemSize + loader.upperMemBase);

    System.setPhysicalAllocator(pmem);

    //v = new(alloc.ptr) VirtualMemory(loader.L4);
    v.init(loader.L4);

    // Map a 16k interrupt stack for IST1
    v.map(cast(void*)0x7FFFC000);
    v.map(cast(void*)0x7FFFD000);
    v.map(cast(void*)0x7FFFE000);
    v.map(cast(void*)0x7FFFF000);

    // Initialize the heap allocator object
    heap = new Heap(&v);
    
    System.setAllocator(heap);
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

    // Set IST entries
    tss.setIstEntry(0, cast(void*)0x7FFFFFF8);
    /*tss.setIstEntry(1, 0x7FFFFFF8);
    tss.setIstEntry(2, 0x7FFFFFF8);
    tss.setIstEntry(3, 0x7FFFFFF8);
    tss.setIstEntry(4, 0x7FFFFFF8);
    tss.setIstEntry(5, 0x7FFFFFF8);
    tss.setIstEntry(6, 0x7FFFFFF8);*/
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
    
    Thread t = new Thread(1, 0);
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
     * Abort execution
     */
    void abort()
    {
        System.output.write("abort!").newline;
        for(;;){}
    }

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
