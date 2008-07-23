/**
 * Base structures for the i586 architecture (GDT, IDT, Page tables, etc...)
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.x86_64.descriptors;

import kernel.arch.util;

import kernel.arch.x86_64.constants;

import std.bitarray;

version(arch_x86_64)
{
    Descriptor[16] gdt;
    TSS tss;

    void setup_gdt()
    {
        // null descriptor
        gdt[0].clear();

        // kernel code descriptor
        gdt[GDTIndex.KERNEL_CODE].clear();
        gdt[GDTIndex.KERNEL_CODE].user = true;
        gdt[GDTIndex.KERNEL_CODE].code = true;
        gdt[GDTIndex.KERNEL_CODE].present = true;
        gdt[GDTIndex.KERNEL_CODE].readable = true;
        gdt[GDTIndex.KERNEL_CODE].scaled = true;
        gdt[GDTIndex.KERNEL_CODE].conforming = false;
        gdt[GDTIndex.KERNEL_CODE].base = 0;
        gdt[GDTIndex.KERNEL_CODE].limit = 0xFFFFF;
        gdt[GDTIndex.KERNEL_CODE].dpl = 0;
        gdt[GDTIndex.KERNEL_CODE].pmode = true;

        // kernel data descriptor
        gdt[GDTIndex.KERNEL_DATA].clear();
        gdt[GDTIndex.KERNEL_DATA].user = true;
        gdt[GDTIndex.KERNEL_DATA].code = false;
        gdt[GDTIndex.KERNEL_DATA].present = true;
        gdt[GDTIndex.KERNEL_DATA].writable = true;
        gdt[GDTIndex.KERNEL_DATA].scaled = true;
        gdt[GDTIndex.KERNEL_DATA].base = 0;
        gdt[GDTIndex.KERNEL_DATA].limit = 0xFFFFF;
        gdt[GDTIndex.KERNEL_DATA].dpl = 0;
        gdt[GDTIndex.KERNEL_DATA].pmode = true;

        // user code descriptor
        gdt[GDTIndex.USER_CODE].clear();
        gdt[GDTIndex.USER_CODE].user = true;
        gdt[GDTIndex.USER_CODE].code = true;
        gdt[GDTIndex.USER_CODE].present = true;
        gdt[GDTIndex.USER_CODE].readable = true;
        gdt[GDTIndex.USER_CODE].scaled = true;
        gdt[GDTIndex.USER_CODE].conforming = false;
        gdt[GDTIndex.USER_CODE].base = 0;
        gdt[GDTIndex.USER_CODE].limit = 0xFFFFF;
        gdt[GDTIndex.USER_CODE].dpl = 3;
        gdt[GDTIndex.USER_CODE].pmode = true;

        // user data descriptor
        gdt[GDTIndex.USER_DATA].clear();
        gdt[GDTIndex.USER_DATA].user = true;
        gdt[GDTIndex.USER_DATA].code = false;
        gdt[GDTIndex.USER_DATA].present = true;
        gdt[GDTIndex.USER_DATA].writable = true;
        gdt[GDTIndex.USER_DATA].scaled = true;
        gdt[GDTIndex.USER_DATA].base = 0;
        gdt[GDTIndex.USER_DATA].limit = 0xFFFFF;
        gdt[GDTIndex.USER_DATA].dpl = 3;
        gdt[GDTIndex.USER_DATA].pmode = true;
        
        // TSS descriptor
        gdt[GDTIndex.TSS].clear();
        gdt[GDTIndex.TSS].base = cast(size_t)&tss;
        gdt[GDTIndex.TSS].limit = TSS.sizeof;
        gdt[GDTIndex.TSS].type = DescriptorType.TSS;
        gdt[GDTIndex.TSS].present = true;
        gdt[GDTIndex.TSS].dpl = 0;

        lgdt(gdt);
    }

    void setup_tss()
    {
        ltr(GDTSelector.TSS);
    }

    void lgdt(Descriptor[] gdt)
    {
        DTPtr gdtp = DTPtr(gdt.length * 8 - 1, cast(uint)gdt.ptr);
        
        asm
        {
            "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
        }
    }

    void lidt(Descriptor[] idt)
    {
        DTPtr idtp = DTPtr(idt.length * 8 - 1, cast(ulong)idt.ptr);

        asm
        {
            "lidt (%[idtp])" : : [idtp] "b" &idtp;
        }
    }

    void ltr(ushort selector)
    {
        asm
        {
            "ltr %[tss_selector]" : : [tss_selector] "b" selector;
        }
    }
}

/**
 * Descriptor table pointer
 * 
 * Used to load a descriptor table
 */
struct DTPtr
{
    union
    {
        byte[6] data;
        BitArray bits;
    }
    
    public static DTPtr opCall(ushort limit, uint address)
    {
        DTPtr t;
        t.bits[0..16] = limit;
        t.bits[16..48] = address;
        return t;
    }
}

enum DescriptorType
{
    TSS = 0x9,
    TSS_BUSY = 0xB,
    CALL_GATE = 0xC,
    INTERRUPT_GATE = 0xE,
    TRAP_GATE = 0xF
}

struct Descriptor
{
    union
    {
        ulong[2] data;
        BitArray bits;
    }
    
    void clear()
    {
        data[0] = 0;
        data[1] = 0;
    }
    
    // Limit property for non-system descriptors
    size_t limit()
    {
        return bits[48..52]<<16 | bits[0..16];
    }
    
    void limit(size_t l)
    {
        l = l & 0xFFFFF;
        
        bits[0..16] = l;
        bits[48..52] = l>>16;
    }
    
    // Base property for non-system descriptors
    size_t base()
    {
        return bits[16..40] | (bits[56..96] << 24);
    }
    
    void base(size_t b)
    {
        bits[16..40] = b;
        bits[56..96] = b>>24;
    }
    
    // Offset property for system descriptors
    size_t offset()
    {
        return bits[0..16] | (bits[48..96]<<16);
    }
    
    void offset(size_t o)
    {
        bits[0..16] = o;
        bits[48..96] = o>>16;
    }
    
    mixin(property!("accessed", "bool", "bits[40]"));
    
    // Code segment properties
    mixin(property!("readable", "bool", "bits[41]"));
    mixin(property!("conforming", "bool", "bits[42]"));
    
    // Data segment properties
    mixin(property!("writable", "bool", "bits[41]"));
    mixin(property!("expanddown", "bool", "bits[42]"));
    
    // System segment properties
    mixin(property!("selector", "ushort", "bits[16..32]"));
    
    // Segment type properties
    mixin(property!("type", "ubyte", "bits[40..44]"));
    mixin(property!("code", "bool", "bits[43]"));
    mixin(property!("user", "bool", "bits[44]"));
    
    mixin(property!("dpl", "size_t", "bits[45..47]"));
    mixin(property!("present", "bool", "bits[47]"));
    
    mixin(property!("pmode", "bool", "bits[54]"));
    mixin(property!("scaled", "bool", "bits[55]"));
}

struct TSS
{
    uint link;
    
    uint esp0;
    uint ss0;
    
    uint esp1;
    uint ss1;

    uint esp2;
    uint ss2;

    uint cr3;
    uint eip;
    uint eflags;
    uint eax;
    uint ecx;
    uint edx;
    uint ebx;
    uint esp;
    uint ebp;
    uint esi;
    uint edi;

    uint es;
    uint cs;
    uint ss;
    uint ds;
    uint fs;
    uint gs;
    uint ldt;
    
    ushort res;
    ushort iopm_offset;
}
