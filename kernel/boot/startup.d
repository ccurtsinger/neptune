module kernel.boot.startup;

import modinit;

import std.stdio;

import arch.x86_64.arch;
import arch.x86_64.descriptor;
import arch.x86_64.gdt;
import arch.x86_64.idt;
import arch.x86_64.paging;

import kernel.core.env;
import kernel.dev.screen;

extern(C) void _startup(LoaderData* loader, ulong* isrtable)
{
    screen = cast(Screen*)0xFFFF8300000B8000;
    screen.clear();
    
    writeln("Running module constructors");
    _moduleCtor();
    
    writeln("Initializing GDT");
    gdt_setup();
    
    writeln("Initializing IDT");
    interrupt_setup(isrtable);
    
    writeln("Initializing memory system");
    memory_setup(loader);
    
    writeln("Running module unit tests");
    _moduleUnitTests();
    
    writeln("Setting up devices");
    kb.init(33);

    
    
    for(;;){}
}

public void gdt_setup()
{
    cpu.gdt.init();
    
    NullDescriptor* n = cpu.gdt.getEntry!(NullDescriptor);
    *n = NullDescriptor();
    
    CodeDescriptor* kc = cpu.gdt.getEntry!(CodeDescriptor);
    *kc = CodeDescriptor();
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
    uc.conforming = false;
    uc.privilege = 3;
    uc.present = true;
    uc.longmode = true;
    uc.operand = false;
    
    DataDescriptor* ud = cpu.gdt.getEntry!(DataDescriptor);
    *ud = DataDescriptor();
    ud.privilege = 3;
    ud.present = true;
    
    cpu.gdt.install();
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
    }
    
    cpu.idt.install();
}

public void memory_setup(LoaderData* loader)
{
    physical.init();
    
    // Use the region of upper memory above the kernel binary
    size_t lowerLimit = loader.usedMemBase + loader.usedMemSize;
    size_t upperLimit = loader.upperMemBase + loader.upperMemSize;
    
    physical.add(lowerLimit, upperLimit - lowerLimit);
    
    cpu.pagetable = cast(PageTable*)ptov(loader.L4);
    
    heap.init(cpu.pagetable);
}
