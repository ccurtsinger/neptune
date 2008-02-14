module kernel.core.interrupt;

import arch.x86_64.idt;

import std.port;
import std.stdio;

import kernel.core.host;

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

struct InterruptScope
{
    InterruptHandler[256] handlers;
    
    public void init()
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
}

extern(C) void _common_interrupt(ulong interrupt, InterruptStack* stack)
{
    if(localscope.handlers[interrupt].set)
    {
        if(!localscope.handlers[interrupt].call(stack))
        {
            host._d_error("Failed interrupt service", "(interrupt)", interrupt);
        }
    }
    else if(interrupt < 32)
    {
        writefln("Interrupt %u", interrupt);
        writefln("  error: %#X", stack.error);
        writefln("  %%rip: %016#X", stack.rip);
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
