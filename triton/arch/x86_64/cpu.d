module arch.x86_64.cpu;

import arch.x86_64.gdt;
import arch.x86_64.idt;
import arch.x86_64.tss;
import arch.x86_64.descriptor;
import arch.x86_64.paging;

struct CPU
{
    GDT gdt;
    IDT idt;
    TSS tss;
    PageTable* pagetable;
}
