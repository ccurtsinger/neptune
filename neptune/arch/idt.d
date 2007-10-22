module neptune.arch.idt;

import std.port;
import std.stdio;
import std.integer;

ulong isrs[256];

// Template for isr extern declarations
template isrGen(int limit, int count = 0) 
{ 
	static if (count==limit)
	{
		const char[] isrGen="";
	}
	else
	{
		const char[] isrGen = "extern(C) void _isr" ~ count.stringof~"(); " ~ isrGen!(limit, count+1);
	}
}

// Template for isr function pointer assignment
template isrMap(int limit, int count = 0) 
{ 
	static if (count==limit)
	{
		const char[] isrMap="";
	}
	else
	{
		const char[] isrMap = "isrs[" ~ count.stringof ~ "] = cast(ulong)&_isr" ~ count.stringof ~ ";" ~ isrMap!(limit, count+1);
	}
}

// Declare isr functions
mixin(isrGen!(256));

// Put pointers to isr functions in the isrs array
private void init_isr_array()
{
	mixin(isrMap!(256));
}

struct IntHandler
{
	ulong base;
	ulong pThis;
}

struct IDTEntry
{
    align(1):
	ushort offset_low;
	ushort selector;
	ubyte  ist;
	ubyte  flags;
	ushort offset_mid;
	uint offset_high;
	uint reserved;

	static IDTEntry opCall(ubyte index, ulong base, ushort selector = 0x08, ubyte flags = 0x8E, ubyte ist = 0)
    {
        IDTEntry entry;

        entry.offset_low = (base & 0xFFFF);
        entry.offset_mid = (base >> 16) & 0xFFFF;
        entry.offset_high = (base >> 32) & 0xFFFFFFFF;

        entry.selector = selector;
        entry.flags = flags;

        entry.ist = ist;
        entry.reserved = 0;

        return entry;
    }
}

struct IDTPtr
{
	align(1):
	ushort limit;
	ulong base;
}

const ubyte PIC1 = 0x20;
const ubyte PIC2 = 0xA0;
const ubyte ICW1 = 0x11;
const ubyte ICW4 = 0x01;
const ubyte PIC_EOI = 0x20;

extern(C) IntHandler _int_handlers[256];

IDTEntry idt[256];
IDTPtr idtp;

void idt_install()
{
    init_isr_array();

    ubyte irqBase = 32;
	ushort irqMask = 0xFFFD;

	idtp.limit = IDTEntry.sizeof*256-1;
	idtp.base = cast(ulong)&idt;

	for(ushort i=0; i<256; i++)
	{
	    idt[i] = IDTEntry(cast(ubyte)i, cast(ulong)isrs[i]);
	    idt_install_default_handler(cast(ubyte)i);
	}

	//idt[33] = IDTEntry(33, cast(ulong)&_isr33);

	asm
	{
	    "cli";
	    "lidt (%[ptr])" : : [ptr] "a" &idtp;
	}

	//Sent ICW1
	outp(PIC1, ICW1);
	outp(PIC2, ICW1);

	//Send ICW2
	outp(PIC1+1, irqBase);
	outp(PIC2+1, irqBase+8);

	//Send ICW3
	outp(PIC1+1, 4);
	outp(PIC2+1, 2);

	//Send ICW4
	outp(PIC1+1, ICW4);
	outp(PIC2+1, ICW4);

	//Disable all but IRQ 1
	outp(PIC1+1, cast(ubyte)(irqMask&0xFF));
	outp(PIC2+1, cast(ubyte)((irqMask>>8)&0xFF));

	asm
	{
	    "sti";
	}
}

void _int_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    writefln("\nInterrupt %u", interrupt);
    writefln("Error Code: %#X", stack.error);
    writefln("  Context\n  -------");
    writefln("  rip    %#016X", stack.rip);
    writefln("  rsp    %#016X", stack.rsp);
    writefln("  rbp    %#016X", stack.rbp);
    writefln("  rax    %#016X", stack.rax);
    writefln("  rbx    %#016X", stack.rbx);
    writefln("  rcx    %#016X", stack.rcx);
    writefln("  rdx    %#016X", stack.rdx);
    writefln("  rsi    %#016X", stack.rsi);
    writefln("  rdi    %#016X", stack.rdi);
    writefln("  r8     %#016X", stack.r8);
    writefln("  r9     %#016X", stack.r9);
    writefln("  r10    %#016X", stack.r10);
    writefln("  r11    %#016X", stack.r11);
    writefln("  r12    %#016X", stack.r12);
    writefln("  r13    %#016X", stack.r13);
    writefln("  r14    %#016X", stack.r14);
    writefln("  r15    %#016X", stack.r15);
    writefln("  ss     %#02X", stack.ss);
    writefln("  cs     %#02X", stack.cs);

    for(;;){}
}

void _irq_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    writefln("\nIRQ %u", interrupt);

    // Acknowledge irq on PIC1
    outp(PIC1, PIC_EOI);

    // Acknowledge irq on PIC2
	if(interrupt >= 40)
		outp(PIC2, PIC_EOI);
}

void idt_install_default_handler(ubyte interrupt)
{
	idt_install_handler(interrupt, cast(ulong)&_int_handler);
}

void idt_install_handler(ubyte interrupt, ulong handler)
{
    _int_handlers[interrupt].base = handler;
    _int_handlers[interrupt].pThis = 0;
}

struct InterruptStack
{
	ulong rax;
	ulong rbx;
	ulong rcx;
	ulong rdx;
	ulong rsi;
	ulong rdi;
	ulong r8;
	ulong r9;
	ulong r10;
	ulong r11;
	ulong r12;
	ulong r13;
	ulong r14;
	ulong r15;
	ulong rbp;
	ulong error;
	ulong rip;
	ulong cs;
	ulong rflags;
	ulong rsp;
	ulong ss;
}
