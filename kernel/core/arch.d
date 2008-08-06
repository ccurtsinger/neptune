/**
 * Architecture-specific setup and runtime code
 *
 * Copyright: 2008 The Neptune Project
 */
 
module kernel.core.arch;

import util.arch.arch;
import util.arch.cpu;
import util.arch.apic;
import util.arch.descriptor;
import util.arch.gdt;
import util.arch.idt;
import util.arch.tss;
import util.arch.paging;

import kernel.core.env;
import kernel.core.interrupt;

void arch_setup()
{
    interrupt_setup();
    
    // Initialize the GDT
    gdt_setup();
    
    // Initialize the CPU Local APIC
    CPU.apic = APIC();
    
    Page* p = (*CPU.pagetable)[0xFFFF85FFFFFFF000];
    p.address = p_alloc();
    p.writable = true;
    p.present = true;
    p.user = false;
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

public void interrupt_setup()
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
    }
    
    CPU.idt[128].privilege = 3;
    CPU.idt[14].stack = 1;
    
    CPU.idt.install();
}
