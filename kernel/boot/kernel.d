/**
 * D entry point for the Neptune Kernel
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.2a
 */

module kernel.boot.kernel;

import std.mem;
import std.modinit;
import std.stdlib;
import std.stdio;

import neptune.arch.gdt;
import neptune.arch.tss;
import neptune.arch.idt;
import neptune.arch.paging;

import kernel.dev.screen;
import kernel.dev.kb;
import kernel.mem.physical;
import kernel.mem.virtual;
import kernel.task.Scheduler;
import kernel.task.Thread;

/// Physical memory allocator that provides pages
PhysicalAllocator pAlloc;

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

/// Paging abstraction
VirtualMemory v;
byte[VirtualMemory.sizeof] alloc; // Space allocated for the virtual memory class

Scheduler scheduler;

const ulong LINEAR_MEM_BASE = 0xFFFF830000000000;

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

    System.output.write("Hello Neptune!").newline;

    System.output.writef("Memory Information:\n - Free: ", cast(void*)pAlloc.sizeFree, "\n - Allocated: ", cast(void*)pAlloc.sizeAllocated).newline;
	
	// Run module constructors and unit tests
	_moduleCtor();
	_moduleUnitTests();
	
	spawn_thread(cast(void*)0x60000000, &thread_function);
	spawn_thread(cast(void*)0x50000000, &thread_function);
	spawn_thread(cast(void*)0x40000000, &thread_function);
		
	while(true)
	{
		char[] line = System.input.readln(screen);
		System.output.write(line);
		delete line;
		writefln("typing in thread %u", scheduler.getThreadID());
		yield();
	}
	
	for(;;){}
}

void thread_function()
{
    while(true)
    {
        writefln("hello from thread %u", scheduler.getThreadID());
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
    
    ulong page_base = cast(ulong)stack;
    ulong mod = page_base % FRAME_SIZE;
    
    if(mod == 0)
        page_base -= FRAME_SIZE;
    else
        page_base -= mod;
        
    map(page_base);
    
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
    pAlloc.init();

    pAlloc.add(loader.lowerMemBase, loader.lowerMemSize);
    pAlloc.add(loader.upperMemBase, loader.usedMemBase - loader.upperMemBase);
    pAlloc.add(loader.usedMemBase + loader.usedMemSize, loader.upperMemSize - loader.usedMemBase - loader.usedMemSize + loader.upperMemBase);

    v = new(alloc.ptr) VirtualMemory(loader.L4);

    // Map a 16k interrupt stack for IST1
    map(0x7FFFC000);
    map(0x7FFFD000);
    map(0x7FFFE000);
    map(0x7FFFF000);

    // Initialize the heap allocator object
    heap.init();
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

    writef("\nPage Fault: %#X", vAddr, "\nMapping...");

    if(v.map(cast(void*)vAddr))
    {
        System.output.write("done").newline;
    }
    else
    {
        System.output.write("failed").newline;
        for(;;){}
    }
}

extern(C)
{
    /**
     * Put a character on the screen
     *
     * Params:
     *  c = character to write to screen
     */
    void putc(char c)
    {
    	if(screen !is null)
			screen.write(c);
    }
    
    /**
     * Get a character from the keyboard
     *
     * Returns: character typed
     */
	char getc()
	{
		return kb.read();
	}
    
    /**
     * Abort execution
     */
    void abort()
    {
        System.output.write("abort!").newline;
        for(;;){}
    }

    /**
     * Allocate memory
     *
     * Params:
     *  s = size of the memory to allocate
     *
     * Returns: pointer to the allocated memory
     */
    void* malloc(size_t s)
    {
        return heap.allocate(s);
    }

    /**
     * Free memory
     * 
     * Params:
     *  p = pointer to the memory to free
     */
    void free(void* p)
    {
        heap.free(p);
    }

    /**
     * Get a free physical page
     *
     * Returns: the physical address of a page of memory
     */
    ulong get_physical_page()
    {
        return pAlloc.allocate();
    }

    /**
     * Determine if a memory address is canonical
     *
     * Params:
     *  vAddr = the address to check
     *
     * Returns: trus if the address is sign-extended above bit 48
     */
    bool is_canonical(void* vAddr)
    {
        ulong a = cast(ulong)vAddr;

        return (0 <= a && a <= 0x00007FFFFFFFFFFF) || (0xFFFF800000000000 <= a && a <= 0xFFFFFFFFFFFFFFFF);
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

    /**
     * Convert a virtual address pointer in the linear-mapped region to a physical address
     *
     * Params:
     *  vAddr = pointer to convert
     *
     * Returns: the physical address of vAddr
     */
    ulong vtop(void* vAddr)
    {
        return (cast(ulong)vAddr) - LINEAR_MEM_BASE;
    }
    
    /**
     * Map a page starting at a given virtual address to some available physical memory
     *
     * Params:
     *  vAddr = address to map
     * 
     * Returns: true if the map was successful
     */
    bool map(ulong vAddr)
    {
        return v.map(cast(void*)vAddr);
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
}
