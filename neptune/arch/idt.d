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

extern(C) IntHandler _int_handlers[256];

const ubyte PIC1 = 0x20;
const ubyte PIC2 = 0xA0;
const ubyte ICW1 = 0x11;
const ubyte ICW4 = 0x01;
const ubyte PIC_EOI = 0x20;

struct IDT
{
	IDTEntry idt[256];
	IDTPtr idtp;
	
	void init()
	{
		init_isr_array();
		
		remapPic();
		
		for(ushort i=0; i<256; i++)
		{
			idt[i] = IDTEntry(i, isrs[i]);
			setDefaultHandler(i);
		}
	}
	
	void remapPic(ubyte base = 32, ushort mask = 0xFFFD)
	{
		//Sent ICW1
		outp(PIC1, ICW1);
		outp(PIC2, ICW1);

		//Send ICW2
		outp(PIC1+1, base);
		outp(PIC2+1, base+8);

		//Send ICW3
		outp(PIC1+1, 4);
		outp(PIC2+1, 2);

		//Send ICW4
		outp(PIC1+1, ICW4);
		outp(PIC2+1, ICW4);

		//Disable all but IRQ 1
		outp(PIC1+1, cast(ubyte)(mask&0xFF));
		outp(PIC2+1, cast(ubyte)((mask>>8)&0xFF));
	}

	void install()
	{
		idtp.limit = IDTEntry.sizeof*256-1;
		idtp.base = cast(ulong)&idt;

		asm
		{
			"cli";
			"lidt (%[ptr])" : : [ptr] "a" &idtp;
		}

		asm
		{
			"sti";
		}
	}

	void _int_handler(ulong interrupt, ulong error, InterruptStack* stack)
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

	void setDefaultHandler(ubyte interrupt)
	{
		setHandler(interrupt, &_int_handler);
	}

	void setHandler(ubyte interrupt, void function(void* p, ulong interrupt, ulong error, InterruptStack* stack) handler)
	{
		_int_handlers[interrupt].base = cast(ulong)handler;
		_int_handlers[interrupt].pThis = 0;
	}
	
	void setHandler(ubyte interrupt, void delegate(ulong interrupt, ulong error, InterruptStack* stack) handler)
	{
		_int_handlers[interrupt].base = cast(ulong)handler.funcptr;
		_int_handlers[interrupt].pThis = cast(ulong)handler.ptr;
	}
}
