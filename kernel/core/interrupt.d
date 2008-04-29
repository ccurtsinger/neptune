/**
 * Interrupt handling code
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module kernel.core.interrupt;

import util.arch.idt;
import util.arch.apic;

import std.port;
import std.stdio;
import std.context;

import kernel.core.env;

/**
 * Abstraction for function and delegate interrupt handlers
 */
struct InterruptHandler
{
    bool set = false;
    bool func;
   
    bool function(Context*) f;
    bool delegate(Context*) d;
   
    /**
     * Call the interrupt handler
     */
    bool call(Context* s)
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
 	void setHandler(ulong interrupt, bool function(Context*) handler)
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
 	void setHandler(ulong interrupt, bool delegate(Context*) handler)
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

extern(C) void _common_interrupt(ulong interrupt, Context* stack)
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
        cpu.disableInterrupts();
        
        writefln("Interrupt %u", interrupt);
        writefln("  error: %#X", stack.error);
        writefln("  %%rip: %p", stack.rip);
        writefln("  %%cs: %#X", stack.cs);
        writefln("  %%ss: %#X", stack.ss);
        writefln("  %%rsp: %p", stack.rsp);
        writefln("  %%rbp: %p", stack.rbp);
        writefln("  %%rax: %p", stack.rax);
        writefln("  %%rbx: %p", stack.rbx);
        writefln("  %%rcx: %p", stack.rcx);
        writefln("  %%rdx: %p", stack.rdx);
        writefln("  %%rdi: %p", stack.rdi);
        writefln("  %%rsi: %p", stack.rsi);
        writefln("  %%rflags: %p", stack.rflags);
        
        version(unwind)
        {
            stackUnwind(cast(ulong*)stack.rsp, cast(ulong*)stack.rbp);
        }
        
        for(;;){}
    }
    
    if(interrupt >= 32 && interrupt < 47)
    {
        outp(PIC1, PIC_EOI);
       
        if(interrupt >= 40)
        {
            outp(PIC2, PIC_EOI);
        }
    }

    cpu.apic.write(APIC_EOI, 1);
}
