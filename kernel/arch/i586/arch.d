module kernel.arch.i586.arch;

import kernel.arch.i586.util;
import kernel.arch.i586.registers;
import kernel.arch.i586.structures;
import kernel.arch.i586.interrupts;
import kernel.arch.i586.pic;

public import kernel.arch.i586.screen;

version(arch_i586)
{
    const size_t FRAME_SIZE = 0x400000;
    const size_t HZ = 4;
    
    const size_t INT_KEYBOARD = 33;
    const size_t INT_MOUSE = 44;

    Descriptor[16] gdt;
    Descriptor[256] idt;

    void startup()
    {
        disable_interrupts();

        PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);

        // Map 0xD0000000 to the first 4MB of memory
        Page* p = pagetable.lookup(0xD0000000);

        p.clear();
        p.base = 0;
        p.writable = true;
        p.present = true;

        // null descriptor
        gdt[0].clear();

        // kernel code descriptor
        gdt[1].clear();
        gdt[1].user = true;
        gdt[1].code = true;
        gdt[1].present = true;
        gdt[1].readable = true;
        gdt[1].scaled = true;
        gdt[1].conforming = false;
        gdt[1].base = 0;
        gdt[1].limit = 0xFFFFF;
        gdt[1].dpl = 0;
        gdt[1].pmode = true;

        // kernel data descriptor
        gdt[2].clear();
        gdt[2].user = true;
        gdt[2].code = false;
        gdt[2].present = true;
        gdt[2].writable = true;
        gdt[2].scaled = true;
        gdt[2].base = 0;
        gdt[2].limit = 0xFFFFF;
        gdt[2].dpl = 0;
        gdt[2].pmode = true;

        // user code descriptor
        gdt[3].clear();
        gdt[3].user = true;
        gdt[3].code = true;
        gdt[3].present = true;
        gdt[3].readable = true;
        gdt[3].scaled = true;
        gdt[3].conforming = false;
        gdt[3].base = 0;
        gdt[3].limit = 0xFFFFF;
        gdt[3].dpl = 3;
        gdt[3].pmode = true;

        // user data descriptor
        gdt[4].clear();
        gdt[4].user = true;
        gdt[4].code = false;
        gdt[4].present = true;
        gdt[4].writable = true;
        gdt[4].scaled = true;
        gdt[4].base = 0;
        gdt[4].limit = 0xFFFFF;
        gdt[4].dpl = 3;
        gdt[4].pmode = true;

        lgdt(gdt);

        // Set up the IDT
        
        for(int i=0; i<idt.length; i++)
        {
            idt[i].clear();
            idt[i].present = true;
            idt[i].dpl = 0;
            idt[i].user = false;
            idt[i].type = 0xE;
            idt[i].selector = 0x8;
        }
        
        mixin(isr_ref!());

        lidt(idt);
        
        remap_pic(32, 0xFFFF);

        enable_interrupts();
        
        screen_mem = cast(byte*)0xC00B8000;
        
        clear_screen();
    }

    void disable_interrupts()
    {
        asm{"cli";}
    }

    void enable_interrupts()
    {
        asm{"sti";}
    }
}

extern(C) void common_interrupt(int interrupt, int ec)
{
    switch(interrupt)
    {
        case 0:
            println("divide by zero exception");
            break;
        case 1:
            println("debug exception");
            break;
        case 2:
            println("non-maskable interrupt");
            break;
        case 3:
            println("breakpoint exception");
            break;
        case 4:
            println("overflow exception");
            break;
        case 5:
            println("bound-range exception");
            break;
        case 6:
            println("invalid opcode");
            break;
        case 7:
            println("device not available");
            break;
        case 8:
            println("double fault");
            break;
        case 9:
            println("coprocessor segment overrun");
            break;
        case 10:
            println("invalid TSS");
            break;
        case 11:
            println("segment not present");
            break;
        case 12:
            println("stack exception");
            break;
        case 13:
            println("general protection fault");
            break;
        case 14:
            println("page fault");
            break;
        case 15:
            println("reserved exception");
            break;
        case 16:
            println("x87 floating point exception");
            break;
        case 17:
            println("alignment check exception");
            break;
        case 18:
            println("machine check exception");
            break;
        case 19:
            println("SIMD floating point exception");
            break;
        case 30:
            println("security exception");
            break;
    }
    
    for(;;){}
}
