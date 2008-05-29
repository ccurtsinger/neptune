module kernel.arch.i586.structures;

import std.bitarray;

Descriptor[16] gdt;
Descriptor[256] idt;

template property(char[] name, char[] type, char[] reference, char[] get = "", char[] set = "")
{
    const char[] property = type ~ " " ~ name ~ "()
    {
        return " ~ reference ~ get ~ ";
    }

    void " ~ name ~ "(" ~ type ~ " value)
    {
        " ~ reference ~ " = value" ~ set ~ ";
    }";
}

/**
 * Descriptor table pointer
 * 
 * Used to load a descriptor table
 */
struct DTPtr
{
    align(1):
    ushort limit;
    ulong address;
    
    public static DTPtr opCall(ushort limit, ulong address)
    {
        DTPtr t;
        t.limit = limit;
        t.address = address;
        return t;
    }
}

struct Descriptor
{
    union
    {
        ulong data;
        BitArray bits;
    }
    
    void clear()
    {
        data = 0;
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
        return bits[16..40] | (bits[56..64] << 24);
    }
    
    void base(size_t b)
    {
        bits[16..40] = b;
        bits[56..64] = b>>24;
    }
    
    // Offset property for system descriptors
    size_t offset()
    {
        return bits[0..16] | (bits[48..64]<<16);
    }
    
    void offset(size_t o)
    {
        bits[0..16] = o;
        bits[48..64] = o>>16;
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

struct Page
{
    union
    {
        uint data;
        BitArray bits;
    }

    void clear()
    {
        data = 0;
        bits[7] = true;
    }

    void invalidate()
    {
        version(arch_i586)
        {
            asm
            {
                "invlpg (%[address])" : : [address] "a" base();
            }
        }
        else
        {
            assert(false, "Unsupported operation on non-native architecute: Page.invalidate()");
        }
    }

    // Define single bit access properties
    mixin(property!("present", "bool", "bits[0]"));
    mixin(property!("writable", "bool", "bits[1]"));
    mixin(property!("user", "bool", "bits[2]"));
    mixin(property!("writethrough", "bool", "bits[3]"));
    mixin(property!("cachedisable", "bool", "bits[4]"));
    mixin(property!("accessed", "bool", "bits[5]"));
    mixin(property!("dirty", "bool", "bits[6]"));
    mixin(property!("global", "bool", "bits[8]"));

    // Define the base address property (shift left 22 bits when getting, right 22 when setting)
    mixin(property!("base", "size_t", "bits[22..32]", "<<22", ">>22"));
}

struct PageTable
{
    private Page[1024] pages;

    Page* lookup(size_t address)
    {
        return &(pages[address>>22]);
    }

    void clear()
    {
        foreach(p; pages)
        {
            p.clear();
        }
    }
}

void lgdt()
{
    DTPtr gdtp = DTPtr(gdt.length * 8 - 1, cast(size_t)gdt.ptr);

    asm
    {
        "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
        
        // Reload the segment selectors
        "jmp $0x8, $reload_cs";
        "reload_cs:";
        "mov $0x10, %%ax";
        "mov %%ax, %%ds";
        "mov %%ax, %%es";
        "mov %%ax, %%fs";
        "mov %%ax, %%gs";
        "mov %%ax, %%ss";
    }
}

void lidt()
{
    DTPtr idtp = DTPtr(idt.length * 8 - 1, cast(ulong)idt.ptr);

    asm
    {
        "lidt (%[idtp])" : : [idtp] "b" &idtp;
    }
}
