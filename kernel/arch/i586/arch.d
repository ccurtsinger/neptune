/**
 * i586 (x86) Architecture Support
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.arch;

import kernel.arch.i586.registers;
import kernel.arch.i586.structures;
import kernel.arch.i586.interrupts;
import kernel.arch.i586.pic;
import kernel.arch.i586.screen;

import std.stdio;

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
        
        screen_mem = cast(byte*)pagetable.reverseLookup(0xB8000);
        
        clear_screen();
    }
    
    size_t ptov(size_t p_addr)
    {
        PageTable* pagetable = cast(PageTable*)(cr3 + 0xC0000000);
        
        size_t v = pagetable.reverseLookup(p_addr);
        
        assert(v != 0, "Physical page unavailable");
        
        return v;
    }

    void disable_interrupts()
    {
        asm{"cli";}
    }

    void enable_interrupts()
    {
        asm{"sti";}
    }
    
    struct Context
    {
        uint eax;
        uint ebx;
        uint ecx;
        uint edx;
        uint esi;
        uint edi;
        uint ebp;
        uint eip;
        uint cs;
        uint flags;
        uint esp;
        uint ss;
    }
}

const char[][] named_exceptions = [ "divide by zero exception",
                                    "debug exception",
                                    "non-maskable interrupt",
                                    "breakpoint exception",
                                    "overflow exception",
                                    "bound-range exception",
                                    "invalid opcode",
                                    "device not available",
                                    "double fault",
                                    "coprocessor segment overrun",
                                    "invalid TSS",
                                    "segment not present",
                                    "stack exception",
                                    "general protection fault",
                                    "page fault",
                                    "reserved exception",
                                    "x87 floating point exception",
                                    "alignment check exception",
                                    "machine check exception",
                                    "SIMD floating point exception"];

extern(C) void common_interrupt(int interrupt, int error, Context* context)
{
    if(interrupt < named_exceptions.length)
    {
        writeln(named_exceptions[interrupt]);
    }
    else
    {
        writefln("interrupt %u", interrupt);
    }
    
    writefln("  error: %02#x", error);
    writefln("   %%eip: %08#x", context.eip);
    writefln("   %%esp: %08#x", context.esp);
    writefln("   %%ebp: %08#x", context.ebp);
    writefln("    %%cs: %02#x", context.cs);
    writefln("    %%ss: %02#x", context.ss);
    writefln("   %%eax: %08#x", context.eax);
    writefln("   %%ebx: %08#x", context.ebx);
    writefln("   %%ecx: %08#x", context.ecx);
    writefln("   %%edx: %08#x", context.edx);
    writefln("   %%esi: %08#x", context.esi);
    writefln("   %%edi: %08#x", context.edi);
    writefln("  flags: %08#x", context.flags);
    
    for(;;){}
}
