module boot.kernel;

import std.stdio;
import std.mem;
static import std.collection.heap;

import neptune.arch.gdt;
import neptune.arch.tss;
import neptune.arch.idt;

import dev.screen;
import dev.kb;
import mem.allocator;

GDT gdt;
TSS tss;
IDT idt;
FixedAllocator pmem;

import mem.paging;

PageTable L4;

import mem.heap;

Heap heap;

extern(C) void _main(LoaderData* loader)
{
    clear_screen();

    // Initialize important data structures
    mem_setup(loader);
    gdt_setup();
    tss_setup();
    idt_setup();

    // Install GDT, IDT, and TSS
    gdt.install();
    tss.install();
    idt.install();

    writefln("Hello D!");
    
    auto h = new std.collection.heap.Heap!(ulong);
    
    h.add(1);
    h.add(2);
    h.add(3);
    
    for(int i=0; i<3; i++)
    {
    	writefln("here: %u", h.get(i));
    }

    for(;;){}
}

void mem_setup(LoaderData* loader)
{
    // Create a new in-place physical memory allocator
    pmem = new(cast(void*)(LINEAR_MEM_BASE + loader.lowerMemBase)) FixedAllocator();

    // Add the lower memory range to the physical allocator
    pmem.addRange(loader.lowerMemBase + FixedAllocator.sizeof, loader.lowerMemSize - FixedAllocator.sizeof);

    // Add the upper memory below the kernel to the physical allocator
    pmem.addRange(loader.upperMemBase, loader.usedMemBase - loader.upperMemBase);

    // Add the upper memory above the kernel to the physical allocator
    pmem.addRange(loader.usedMemBase+loader.usedMemSize, loader.upperMemSize-loader.usedMemBase-loader.usedMemSize+loader.upperMemBase);

    // Point the L4 page table to the address passed by the 32 bit loader
    L4.init(PAGEDIR_L4, loader.L4);

    // Map an 8k interrupt stack for IST1
    L4.map(0x7FFFC000, FRAME_SIZE*4);

    // Initialize the heap allocator object
    heap.init();
}

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
    ushort tssSelector = gdt.addEntry(GDTEntry(cast(ulong)&tss));

    tss.setSelector(tssSelector);
}

void tss_setup()
{
    tss.init();

    // Set the permission-level stacks
    tss.setRspEntry(0, 0xFFFF810000000000);
    tss.setRspEntry(1, 0xFFFF810000000000);
    tss.setRspEntry(2, 0xFFFF810000000000);

    // Set IST entries
    tss.setIstEntry(0, 0x7FFFFFF8);
    /*tss.setIstEntry(1, 0x7FFFFFF8);
    tss.setIstEntry(2, 0x7FFFFFF8);
    tss.setIstEntry(3, 0x7FFFFFF8);
    tss.setIstEntry(4, 0x7FFFFFF8);
    tss.setIstEntry(5, 0x7FFFFFF8);
    tss.setIstEntry(6, 0x7FFFFFF8);*/
}

void idt_setup()
{
	idt.init();
	
	// Install the page fault handler
	idt.setHandler(14, &pagefault_handler);
	
	// Initialize keyboard data and install the interrupt handler
	kb_setup();
    idt.setHandler(33, &kb_handler);
}

void pagefault_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    ulong vAddr;
	asm
	{
	    "mov %%cr2, %[addr]" : [addr] "=a" vAddr;
    }

    writef("\nPage Fault: %016#X\nMapping...", vAddr);

    if(L4.map(vAddr))
        writeln("done");
    else
    {
        writeln("failed");
        for(;;){}
    }
}

extern(C)
{
    void abort()
    {
        write("abort!\n");
        for(;;){}
    }

    void* malloc(ulong s)
    {
        //write("malloc\n");
        return heap.allocate(s);
    }

    void free(void* p)
    {
        write("free\n");
        heap.free(p);
    }

    int strlen(char* s)
    {
        int len = 0;

        while(s[len] != '\0')
        {
            len++;
        }

        return len;
    }
}

struct LoaderData
{
    align(1):
	ulong L4;
	ulong usedMemBase;
	ulong usedMemSize;
	ulong lowerMemBase;
	ulong lowerMemSize;
	ulong upperMemBase;
	ulong upperMemSize;
	ulong regions;
	ulong memInfo;
}
