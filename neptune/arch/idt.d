/**
 * IDT Abstraction and Utilities
 *
 * Authors: Charlie Curtsinger
 * Date: October 28th, 2007
 * Version: 0.1a
 */

module neptune.arch.idt;

import std.port;
import std.stdio;
import std.integer;

/// Array of isr addresses
void* isrs[256];


/// Table of interrupt handler addresses (and 'this' pointers) for isrs
extern(C) IntHandler _int_handlers[256];

const ubyte PIC1 = 0x20;
const ubyte PIC2 = 0xA0;
const ubyte ICW1 = 0x11;
const ubyte ICW4 = 0x01;
const ubyte PIC_EOI = 0x20;

/**
 * Template for isr extern declarations
 * 
 * Automatically generates 'extern(C) _isr#();' for every isr 0 to 255
 */
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

/**
 * Template for isr function pointer array initialization
 *
 * Automatically puts the address of _isr# into isrs[#] for easy access
 */
template isrMap(int limit, int count = 0) 
{ 
	static if (count==limit)
	{
		const char[] isrMap="";
	}
	else
	{
		const char[] isrMap = "isrs[" ~ count.stringof ~ "] = &_isr" ~ count.stringof ~ ";" ~ isrMap!(limit, count+1);
	}
}

/// Declare isr functions
mixin(isrGen!(256));

/// Put pointers to isr functions in the isrs array using the isrMap template
private void init_isr_array()
{
	mixin(isrMap!(256));
}

/**
 * Struct referenced by isrs to locate interrupt handlers
 *
 * Supports delegates and functions
 */
struct IntHandler
{
	void* base;
	void* pThis;
}

/**
 * A single entry in the IDT
 */
struct IDTEntry
{
    align(1):
    
    /// Bottom 2 bytes of isr address
	ushort offset_low;
	
	/// Code selector to use for isr
	ushort selector;
	
	/// Index into the interrupt stack table - 0 through 7 (0 is null)
	ubyte  ist;
	
	/// Additional flags
	ubyte  flags;
	
	/// Bytes 3 and 4 of isr address
	ushort offset_mid;
	
	/// High four bytes of isr address
	uint offset_high;
	
	/// Reserved space
	uint reserved;

	/**
	 * Create an IDT entry
	 *
	 * Params:
	 *  base = Address of the isr
	 *  selector = code segment selector
	 *  flags = Additional flags
	 *  ist = IST index - 0 means use existing stack
	 *
	 * Returns: Newly created IDT entry object
	 */
	static IDTEntry opCall(void* base, ushort selector = 0x08, ubyte flags = 0x8E, ubyte ist = 0)
    {
        IDTEntry entry;

        entry.offset_low = (cast(ulong)base & 0xFFFF);
        entry.offset_mid = (cast(ulong)base >> 16) & 0xFFFF;
        entry.offset_high = (cast(ulong)base >> 32) & 0xFFFFFFFF;

        entry.selector = selector;
        entry.flags = flags;

        entry.ist = ist;
        entry.reserved = 0;

        return entry;
    }
}

/**
 * Abstraction for the Interrupt Descriptor Table
 */
struct IDT
{
	/// Contents of the table
	IDTEntry idt[256];
	
	/// IDT pointer used to load the IDT
	IDTPtr idtp;
	
	/**
	 * Initialize the IDT
	 *
	 * Creates an array of ISRs
	 * Remaps the PIC
	 * Adds ISRs to IDT
	 * Sets default handlers for all interrupts
	 */
	void init()
	{
		init_isr_array();
		
		remapPic();
		
		for(ushort i=0; i<256; i++)
		{
			idt[i] = IDTEntry(isrs[i]);
			setDefaultHandler(i);
		}
	}

	/**
	 * Install the IDT and enable interrupts
	 */
	void install()
	{
		idtp.limit = IDTEntry.sizeof*256-1;
		idtp.base = idt.ptr;

		asm
		{
			"cli";
			"lidt (%[ptr])" : : [ptr] "a" &idtp;
			"sti";
		}
	}

	/**
	 * Install the default interrupt handler for a given interrupt
	 *
	 * @param interrupt		Index of the interrupt to set the handler for
	 */
	void setDefaultHandler(ubyte interrupt)
	{
		setHandler(interrupt, &_int_handler);
	}

	/**
	 * Install a non-member handler for an interrupt
	 *
	 * Params:
	 *  interrupt = Index of the interrupt to set the handler for
	 *  handler = Function pointer to the interrupt handler
	 */
	void setHandler(ubyte interrupt, void function(void* p, ulong interrupt, ulong error, InterruptStack* stack) handler)
	{
		_int_handlers[interrupt].base = handler;
		_int_handlers[interrupt].pThis = null;
	}
	
	/**
	 * Install an object-member interrupt handler for a given interrupt
	 *
	 * Params:
	 *  interrupt = Index of the interrupt to set the handler for
	 *  handler = Delegate to teh interrupt handler
	 */
	void setHandler(ubyte interrupt, void delegate(ulong interrupt, ulong error, InterruptStack* stack) handler)
	{
		_int_handlers[interrupt].base = handler.funcptr;
		_int_handlers[interrupt].pThis = handler.ptr;
	}
	
	/**
	 * Struct used for loading IDT
	 */
	struct IDTPtr
	{
		align(1):
		ushort limit;
		void* base;
	}
}

/**
 * Remap the PIC to deliver IRQs at 'base', if the corresponding bit is cleared in 'mask'
 */
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

/**
 * Contents of the stack inside an interrupt handler
 */
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

/**
 * Default interrupt handler
 *
 * Params:
 *  p = empty pointer - used for compatibility with delegate handlers
 *  interrupt = interrupt number
 *  error = error code (or 0)
 *  stack = pointer to pre-interrupt context information on the stack
 */
void _int_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
	writefln("\nInterrupt %u", interrupt);
	writefln("Error Code: %#X", stack.error);
	writefln("  Context\n  -------");
	writefln("  rip    %#016X", stack.rip);
	writefln("  rsp    %#016X", stack.rsp);
	writefln("  rbp    %#016X", stack.rbp);
	/*writefln("  rax    %#016X", stack.rax);
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
	writefln("  r15    %#016X", stack.r15);*/
	writefln("  ss     %#02X", stack.ss);
	writefln("  cs     %#02X", stack.cs);

	for(;;){}
}

/**
 * Default IRQ handler
 *
 * Params:
 *  p = empty pointer -used for compatibility with delegate handlers
 *  interrupt = interrupt number (NOT IRQ NUMBER)
 *  error = error code (0 for IRQs)
 *  stack = pointer to pre-interrupt context information on the stack
 */
void _irq_handler(void* p, ulong interrupt, ulong error, InterruptStack* stack)
{
	writefln("\nIRQ %u", interrupt);

	// Acknowledge irq on PIC1
	outp(PIC1, PIC_EOI);

	// Acknowledge irq on PIC2
	if(interrupt >= 40)
		outp(PIC2, PIC_EOI);
}
