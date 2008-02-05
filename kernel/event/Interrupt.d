/**
 * Interrupt handling utilities
 *
 * Authors: Charlie Curtsinger
 * Date: January 15th, 2008
 * Version: 0.2a
 */

module kernel.event.Interrupt;

import kernel.arch.IDT;
import std.port;
import std.event.Event;

import kernel.event.Event;

/**
 * Struct for the stack in an interrupt handler
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
 * Abstraction for function and delegate interrupt handlers
 */
struct InterruptHandler
{
    bool set = false;
    bool func;
    
    bool function(InterruptStack*) f;
    bool delegate(InterruptStack*) d;
    
    /**
     * Call the interrupt handler
     */
    bool call(InterruptStack* s)
    {
        assert(set, "Attempted to call null InterruptHandler");
        
        if(func)
            return f(s);
        else
            return d(s);
    }
}

InterruptHandler[256] handlers;

/**
 * Initialize the interrupt handler array
 */
static this()
{
    for(size_t i=0; i<handlers.length; i++)
    {
        handlers[i].set = false;
    }
}

/**
 * Set a function as an interrupt handler
 */
void setHandler(ulong interrupt, bool function(InterruptStack*) handler)
{
    if(handler !is null)
    {
        handlers[interrupt].set = true;
        handlers[interrupt].func = true;
        handlers[interrupt].f = handler;
    }
    else
    {
        handlers[interrupt].set = false;
    }
}

/**
 * Set a delegate as an interrupt handler
 */
void setHandler(ulong interrupt, bool delegate(InterruptStack*) handler)
{
    if(handler !is null)
    {
        handlers[interrupt].set = true;
        handlers[interrupt].func = false;
        handlers[interrupt].d = handler;
    }
    else
    {
        handlers[interrupt].set = false;
    }
}

/**
 * Interrupt handler called by the assembly ISRs
 */
extern(C) void _common_interrupt(ulong interrupt, InterruptStack* stack)
{
    if(handlers[interrupt].set)
    {
        if(!handlers[interrupt].call(stack))
        {
            System.output.write("System halted").newline;
            for(;;){}
        }
    }
    else if(interrupt < 32)
    {
        System.output.writef("interrupt %u", interrupt).newline;
        System.output.writef("error: %#X", stack.error).newline;
        System.output.writef("%%rip: %016#X", stack.rip).newline;
    
        for(;;){}
    }
    else if(interrupt == 33)
    {
    	System.dispatcher.dispatch(new KeyboardIRQEvent(stack));
    }
    else
    {
    	System.output.writef("interupt %u", interrupt).newline;
    }
    
    if(interrupt >= 32 && interrupt < 47)
    {
    	outp(PIC1, PIC_EOI);
    	
    	if(interrupt >= 40)
    	{
    		outp(PIC2, PIC_EOI);
    	}
    }
}

class InterruptEvent : Event
{
	InterruptStack* context;
	
	public this(InterruptStack* context)
	{
		this.context = context;
	}
}

class TimerIRQEvent : InterruptEvent
{
	public this(InterruptStack* context)
	{
		super(context);
	}
}

class KeyboardIRQEvent : InterruptEvent
{
	public this(InterruptStack* context)
	{
		super(context);
	}
}

class MouseIRQEvent : InterruptEvent
{
	public this(InterruptStack* context)
	{
		super(context);
	}
}
