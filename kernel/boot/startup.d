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
import std.port;
import std.mem.AddressSpace;
import std.event.Dispatcher;

import kernel.kernel;

import kernel.arch.Arch;
import kernel.arch.Descriptor;
import kernel.arch.GDT;
import kernel.arch.IDT;
import kernel.arch.TSS;
import kernel.arch.PageTable;

import kernel.mem.PhysicalAllocator;
import kernel.mem.HeapAllocator;
import kernel.mem.DummyAllocator;
import kernel.mem.StackAllocator;

import kernel.dev.Screen;
import kernel.dev.Keyboard;
import kernel.dev.Mouse;

import kernel.event.Interrupt;

import kernel.task.Scheduler;
import kernel.task.Thread;

/// GDT
GDT gdt;

/// TSS
TSS tss;

/// IDT
IDT idt;

PageTable* L4;

BasicScheduler scheduler;

Dispatcher dispatcher;

/**
 * Starting function for D
 *
 * Params:
 *  loader = Pointer to the loader data struct - contains memory information
 *  isrtable = Array of virtual addresses for interrupt service routines (256 ulongs)
 */
extern(C) void _main(LoaderData* loader, ulong* isrtable)
{
	// Initialize important data structures
    mem_setup(loader);
    idt_setup(isrtable);
    tss_setup();
    gdt_setup();
    
    _moduleCtor();
	
    dispatcher = new Dispatcher();
	System.dispatcher = dispatcher;
    
    Screen screen = new Screen();
    screen.clear();
    
    System.output = screen;
    System.error = screen;
    
    Keyboard kb = new Keyboard();
    System.input = kb;
	
	setHandler(14, &pagefault_handler);
	
	scheduler = new BasicScheduler();
	System.scheduler = scheduler;
	
	KernelThread t = new KernelThread(&main);
	
	t.start();
	
    // Install GDT, IDT, and TSS
    gdt.install();
    tss.install();
    idt.install();

	_moduleUnitTests();
	
	System.scheduler.taskSwitch();
	
	for(;;){}
}

/**
 * Called on kernel exit
 */
extern(C) void _exit()
{
	System.output.write("Kernel exited").newline;
	
	_moduleDtor();
	
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
    HeapAllocator heap;
    StackAllocator stack;
    
    AddressSpace mem;
    
    void* alloc = loader.tempData;

    mem = new(alloc) AddressSpace();
    alloc += FRAME_SIZE;
    dummyAllocator = new(alloc) DummyAllocator();
    alloc += FRAME_SIZE;
    dummyAllocator.add(alloc, loader.tempDataSize - FRAME_SIZE);
    
    System.memory = mem;
    
    mem.setAllocator(dummyAllocator);
    
    pmem = new PhysicalAllocator();

    pmem.add(loader.lowerMemBase, loader.lowerMemSize);
    pmem.add(loader.upperMemBase, loader.usedMemBase - loader.upperMemBase);
    pmem.add(loader.usedMemBase + loader.usedMemSize, loader.upperMemSize - loader.usedMemBase - loader.usedMemSize + loader.upperMemBase);

    mem.setPhysicalAllocator(pmem);

    L4 = cast(PageTable*)ptov(loader.L4);
    
    Page* p;
    
    p = (*L4)[0x7FFFC000];
    p.address = System.memory.physical.getPage();
    p.superuser = true;
    p.writable = true;
    p.present = true;
    p.invalidate();
    
    p = (*L4)[0x7FFFD000];
    p.address = System.memory.physical.getPage();
    p.superuser = true;
    p.writable = true;
    p.present = true;
    p.invalidate();
    
    p = (*L4)[0x7FFFE000];
    p.address = System.memory.physical.getPage();
    p.superuser = true;
    p.writable = true;
    p.present = true;
    p.invalidate();
    
    p = (*L4)[0x7FFFF000];
    p.address = System.memory.physical.getPage();
    p.superuser = true;
    p.writable = true;
    p.present = true;
    p.invalidate();

    // Initialize the heap allocator object
    heap = new HeapAllocator(L4);
    
    mem.setAllocator(heap);
    
    stack = new StackAllocator(L4);
    
    mem.setStackAllocator(stack);
}

/**
 * Add necessary entries to the GDT
 */
void gdt_setup()
{
    gdt.init();
    
    NullDescriptor* n = gdt.getEntry!(NullDescriptor);
    *n = NullDescriptor();
    
    CodeDescriptor* kc = gdt.getEntry!(CodeDescriptor);
    *kc = CodeDescriptor();
    kc.conforming = false;
    kc.privilege = 0;
    kc.present = true;
    kc.longmode = true;
    kc.operand = false;
    
    DataDescriptor* kd = gdt.getEntry!(DataDescriptor);
    *kd = DataDescriptor();
    kd.privilege = 0;
    kd.writable = true;
    kd.present = true;
    
    CodeDescriptor* uc = gdt.getEntry!(CodeDescriptor);
    *uc = CodeDescriptor();
    uc.conforming = false;
    uc.privilege = 3;
    uc.present = true;
    uc.longmode = true;
    uc.operand = false;
    
    DataDescriptor* ud = gdt.getEntry!(DataDescriptor);
    *ud = DataDescriptor();
    ud.privilege = 3;
    ud.present = true;
    
    SystemDescriptor* t = gdt.getEntry!(SystemDescriptor);
    *t = SystemDescriptor();
    t.base = tss.address;
    t.limit = 0x67;
    t.type = DescriptorType.TSS;
    t.privilege = 0;
    t.present = true;
    t.granularity = false;
}

/**
 * Create and initialize a TSS with IST
 */
void tss_setup()
{
    tss = new TSS();
    
    tss.selector = 0x28;
    
    tss.rsp0 = 0xFFFF810000000000;
    tss.rsp1 = 0xFFFF810000000000;
    tss.rsp2 = 0xFFFF810000000000;
    
    tss.ist1 = 0x7FFFFFF8;
}

/**
 * Set up an IDT and install handlers for keyboard an page fault
 */
void idt_setup(ulong* isrtable)
{
    for(size_t i=0; i<256; i++)
    {
        GateDescriptor* d = idt[i];
        
        *d = GateDescriptor();
        
        d.target = isrtable[i];
        d.selector = 0x08;
        d.type = DescriptorType.INTERRUPT;
        d.stack = 0;
        d.privilege = 0;
        d.present = true;
        
        if(i == 14 || i == 32)
        {
        	d.stack = 0;
        }
    }
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
bool pagefault_handler(InterruptStack* stack)
{
    ulong vAddr;
	asm
	{
	    "mov %%cr2, %[addr]" : [addr] "=a" vAddr;
    }

    System.output.writef("\nPage Fault: %#X %#X", vAddr, stack.error).newline;
    System.output.writef("%016#X", stack.rip).newline;
    
    Page* p = (*L4)[vAddr];
    p.present = true;
    p.writable = true;
    p.address = System.memory.physical.getPage();
    p.superuser = true;
    p.invalidate();
    
    return true;
}

/**
 * Data passed from the 32 bit loader
 */
struct LoaderData
{
    align(1):
    /// Physical address of the top-level page directory
	paddr_t L4;
	
	/// Base address of the used memory
	paddr_t usedMemBase;
	
	/// Size of the used memory
	size_t usedMemSize;
	
	/// Base address of lower memory
	paddr_t lowerMemBase;
	
	/// Size of lower memory
	size_t lowerMemSize;
	
	/// Base address of upper memory
	paddr_t upperMemBase;
	
	/// Size of upper memory
	size_t upperMemSize;
	
	ulong regions;
	
	ulong memInfo;
	
	void* tempData;
	
	size_t tempDataSize;
}
