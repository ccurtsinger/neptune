module interrupt.idt;

import interrupt.isr;
import dev.port;
import dev.screen;
import mem.util;

struct IntHandler
{
	ulong base;
	ulong pThis;
}

struct IDTEntry
{
	ushort offset_low;
	ushort selector;
	ubyte  ist;
	ubyte  flags;
	ushort offset_mid;
	uint offset_high;
	uint reserved;
}

/// Data structure used to load the IDT
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
    ubyte irqBase = 32;
	ushort irqMask = 0xFFFD;

	memset(cast(byte*)&idt, 0, IDTEntry.sizeof*256);

	idtp.limit = IDTEntry.sizeof*256-1;
	idtp.base = cast(ulong)&idt;

    idt_set_entry(0, cast(ulong)(&_isr0), 0x08, 0x8E, 1);
	idt_set_entry(1, cast(ulong)(&_isr1), 0x08, 0x8E, 1);
	idt_set_entry(2, cast(ulong)(&_isr2), 0x08, 0x8E, 1);
	idt_set_entry(3, cast(ulong)(&_isr3), 0x08, 0x8E, 1);
	idt_set_entry(4, cast(ulong)(&_isr4), 0x08, 0x8E, 1);
	idt_set_entry(5, cast(ulong)(&_isr5), 0x08, 0x8E, 1);
	idt_set_entry(6, cast(ulong)(&_isr6), 0x08, 0x8E, 1);
	idt_set_entry(7, cast(ulong)(&_isr7), 0x08, 0x8E, 1);
	idt_set_entry(8, cast(ulong)(&_isr8), 0x08, 0x8E, 1);
	idt_set_entry(9, cast(ulong)(&_isr9), 0x08, 0x8E, 1);
	idt_set_entry(10, cast(ulong)(&_isr10), 0x08, 0x8E, 1);
	idt_set_entry(11, cast(ulong)(&_isr11), 0x08, 0x8E, 1);
	idt_set_entry(12, cast(ulong)(&_isr12), 0x08, 0x8E, 1);
	idt_set_entry(13, cast(ulong)(&_isr13), 0x08, 0x8E, 1);
	idt_set_entry(14, cast(ulong)(&_isr14), 0x08, 0x8E, 1);
	idt_set_entry(15, cast(ulong)(&_isr15), 0x08, 0x8E, 1);

	idt_set_entry(16, cast(ulong)(&_isr16), 0x08, 0x8E, 1);
	idt_set_entry(17, cast(ulong)(&_isr17), 0x08, 0x8E, 1);
	idt_set_entry(18, cast(ulong)(&_isr18), 0x08, 0x8E, 0);
	idt_set_entry(19, cast(ulong)(&_isr19), 0x08, 0x8E, 0);
	idt_set_entry(20, cast(ulong)(&_isr20), 0x08, 0x8E, 0);
	idt_set_entry(21, cast(ulong)(&_isr21), 0x08, 0x8E, 0);
	idt_set_entry(22, cast(ulong)(&_isr22), 0x08, 0x8E, 0);
	idt_set_entry(23, cast(ulong)(&_isr23), 0x08, 0x8E, 0);
	idt_set_entry(24, cast(ulong)(&_isr24), 0x08, 0x8E, 0);
	idt_set_entry(25, cast(ulong)(&_isr25), 0x08, 0x8E, 0);
	idt_set_entry(26, cast(ulong)(&_isr26), 0x08, 0x8E, 0);
	idt_set_entry(27, cast(ulong)(&_isr27), 0x08, 0x8E, 0);
	idt_set_entry(28, cast(ulong)(&_isr28), 0x08, 0x8E, 0);
	idt_set_entry(29, cast(ulong)(&_isr29), 0x08, 0x8E, 0);
	idt_set_entry(30, cast(ulong)(&_isr30), 0x08, 0x8E, 0);
	idt_set_entry(31, cast(ulong)(&_isr31), 0x08, 0x8E, 0);

	idt_set_entry(32, cast(ulong)(&_isr32), 0x08, 0x8E, 0);
	idt_set_entry(33, cast(ulong)(&_isr33), 0x08, 0x8E, 1);
	idt_set_entry(34, cast(ulong)(&_isr34), 0x08, 0x8E, 0);
	idt_set_entry(35, cast(ulong)(&_isr35), 0x08, 0x8E, 0);
	idt_set_entry(36, cast(ulong)(&_isr36), 0x08, 0x8E, 0);
	idt_set_entry(37, cast(ulong)(&_isr37), 0x08, 0x8E, 0);
	idt_set_entry(38, cast(ulong)(&_isr38), 0x08, 0x8E, 0);
	idt_set_entry(39, cast(ulong)(&_isr39), 0x08, 0x8E, 0);
	idt_set_entry(40, cast(ulong)(&_isr40), 0x08, 0x8E, 0);
	idt_set_entry(41, cast(ulong)(&_isr41), 0x08, 0x8E, 0);
	idt_set_entry(42, cast(ulong)(&_isr42), 0x08, 0x8E, 0);
	idt_set_entry(43, cast(ulong)(&_isr43), 0x08, 0x8E, 0);
	idt_set_entry(44, cast(ulong)(&_isr44), 0x08, 0x8E, 0);
	idt_set_entry(45, cast(ulong)(&_isr45), 0x08, 0x8E, 0);
	idt_set_entry(46, cast(ulong)(&_isr46), 0x08, 0x8E, 0);
	idt_set_entry(47, cast(ulong)(&_isr47), 0x08, 0x8E, 1);

	for(ushort i=0; i<256; i++)
	{
	    idt_install_default_handler(cast(ubyte)i);
	}

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

void idt_set_entry(ubyte index, ulong base, ushort selector, ubyte flags, ubyte ist)
{
	idt[index].offset_low = (base & 0xFFFF);
	idt[index].offset_mid = (base >> 16) & 0xFFFF;
	idt[index].offset_high = (base >> 32) & 0xFFFFFFFF;

	idt[index].selector = selector;
	idt[index].flags = flags;

	idt[index].ist = ist;
	idt[index].reserved = 0;
}

void _int_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    writefln("\nInterrupt %u", interrupt);
    writefln("Error Code: %#X", stack.error);
    writefln("  Context\n  -------");
    writefln("  rip    %#016X", stack.rip);
    writefln("  rsp    %#016X", stack.rsp);
    writefln("  rbp    %#016X", stack.rbp);
    //writefln("  rax    %#016X", stack.rax);
    //writefln("  rbx    %#016X", stack.rbx);
    //writefln("  rcx    %#016X", stack.rcx);
    //writefln("  rdx    %#016X", stack.rdx);
    //writefln("  rsi    %#016X", stack.rsi);
    //writefln("  rdi    %#016X", stack.rdi);
    //writefln("  r8     %#016X", stack.r8);
    //writefln("  r9     %#016X", stack.r9);
    //writefln("  r10    %#016X", stack.r10);
    //writefln("  r11    %#016X", stack.r11);
    //writefln("  r12    %#016X", stack.r12);
    //writefln("  r13    %#016X", stack.r13);
    //writefln("  r14    %#016X", stack.r14);
    //writefln("  r15    %#016X", stack.r15);
    writefln("  ss     %#02X", stack.ss);
    writefln("  cs     %#02X", stack.cs);

    for(;;){}
}

void _irq_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
    print("\nIRQ ");
    print_uint_dec(interrupt);
    print("\n");

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
