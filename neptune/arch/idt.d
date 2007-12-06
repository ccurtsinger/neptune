/**
 * IDT Abstraction and Utilities
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module neptune.arch.idt;

import std.port;
import std.integer;

/// Array of isr addresses
void* isrs[256];

/// Table of interrupt handler addresses (and 'this' pointers) for isrs
extern(C) IntHandler interruptHandlers[256];

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
	bool func;
	void function(ulong interrupt, InterruptStack* stack) functionHandler;
	void delegate(ulong interrupt, InterruptStack* stack) delegateHandler;
	
	static IntHandler opCall(void function(ulong interrupt, InterruptStack* stack) handler)
	{
	    IntHandler i;
	    
	    i.func = true;
	    i.functionHandler = handler;
	    
	    return i;
	}
	
	static IntHandler opCall(void delegate(ulong interrupt, InterruptStack* stack) handler)
	{
	    IntHandler i;
	    
	    i.func = false;
	    i.delegateHandler = handler;
	    
	    return i;
	}
	
	void call(ulong interrupt, InterruptStack* stack)
	{
	    if(func)
            functionHandler(interrupt, stack);
        else
            delegateHandler(interrupt, stack);
	}
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
		
		remapPic(32, 0xFFFD);
		
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
		setHandler(interrupt, &defaultHandler);
	}

	/**
	 * Install a non-member handler for an interrupt
	 *
	 * Params:
	 *  interrupt = Index of the interrupt to set the handler for
	 *  handler = Function pointer to the interrupt handler
	 */
	void setHandler(ubyte interrupt, void function(ulong interrupt, InterruptStack* stack) handler)
	{
	    interruptHandlers[interrupt] = IntHandler(handler);
	}
	
	/**
	 * Install an object-member interrupt handler for a given interrupt
	 *
	 * Params:
	 *  interrupt = Index of the interrupt to set the handler for
	 *  handler = Delegate to teh interrupt handler
	 */
	void setHandler(ubyte interrupt, void delegate(ulong interrupt, InterruptStack* stack) handler)
	{
		interruptHandlers[interrupt] = IntHandler(handler);
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
void remapPic(ubyte base = 32, ushort mask = 0x0)
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

extern(C) void _common_interrupt(ulong interrupt, InterruptStack* stack)
{
    interruptHandlers[interrupt].call(interrupt, stack);
}

void defaultHandler(ulong interrupt, InterruptStack* stack)
{
    System.output.writef("Unhandled interrupt: %u", interrupt).newline;
    
    for(;;){}
}

void stackUnwind(ulong stack, ulong frame, size_t depth = 6)
{
	ulong* rsp = cast(ulong*)stack;
	ulong* rbp = cast(ulong*)frame;
	
	for(size_t i=0; i<depth; i++)
	{
		rsp = rbp;
		rbp = cast(ulong*)rsp[0];
		System.output.writef("unwind %016#X", rsp[1]).newline;
	}
}
