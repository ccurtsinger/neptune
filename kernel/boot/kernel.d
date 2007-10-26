module boot.kernel;

import std.stdio;
import std.mem;
import std.collection.stack;
import std.kernel;

import neptune.arch.gdt;
import neptune.arch.tss;
import neptune.arch.idt;
import neptune.arch.paging;
import neptune.mem.allocate.physical;

import dev.screen;
import dev.kb;
import mem.heap;

PhysicalAllocator pAlloc;
GDT gdt;
TSS tss;
IDT idt;
PageTable L4;
Heap heap;

const ulong LINEAR_MEM_BASE = 0xFFFF830000000000;

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

    writeln("Hello D!");

    writefln("Memory Information:\n - Free: %016#X\n - Allocated: %016#X", pAlloc.sizeFree, pAlloc.sizeAllocated);

    for(;;){}
}

void mem_setup(LoaderData* loader)
{
    pAlloc.init();

    pAlloc.add(loader.lowerMemBase, loader.lowerMemSize);
    pAlloc.add(loader.upperMemBase, loader.usedMemBase - loader.upperMemBase);
    pAlloc.add(loader.usedMemBase + loader.usedMemSize, loader.upperMemSize - loader.usedMemBase - loader.usedMemSize + loader.upperMemBase);

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
        return heap.allocate(s);
    }

    void free(void* p)
    {
        heap.free(p);
    }

    ulong get_physical_page()
    {
        return pAlloc.allocate();
    }

    bool is_canonical(void* vAddr)
    {
        ulong a = cast(ulong)vAddr;

        return (0 <= a && a <= 0x00007FFFFFFFFFFF) || (0xFFFF800000000000 <= a && a <= 0xFFFFFFFFFFFFFFFF);
    }

    void* ptov(ulong pAddr)
    {
        return cast(void*)(pAddr + LINEAR_MEM_BASE);
    }

    ulong vtop(void* vAddr)
    {
        return (cast(ulong)vAddr) - LINEAR_MEM_BASE;
    }

    bool map(ulong vAddr)
    {
        return L4.map(vAddr);
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
