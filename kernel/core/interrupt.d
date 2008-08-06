/**
 * Interrupt handling code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core.interrupt;

import util.arch.cpu;
import util.arch.idt;
import util.arch.apic;

import std.port;
import std.stdio;
import std.context;

import kernel.core.env;

ulong[256] isrtable;

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
        
        for(size_t i=0; i<256; i++)
        {
            isrtable[i] = cast(ulong)&isr_0;
        }
        
        isrtable[0] = cast(ulong)&isr_0;
        isrtable[1] = cast(ulong)&isr_1;
        isrtable[2] = cast(ulong)&isr_2;
        isrtable[3] = cast(ulong)&isr_3;
        isrtable[4] = cast(ulong)&isr_4;
        isrtable[5] = cast(ulong)&isr_5;
        isrtable[6] = cast(ulong)&isr_6;
        isrtable[7] = cast(ulong)&isr_7;
        isrtable[8] = cast(ulong)&isr_8;
        isrtable[10] = cast(ulong)&isr_10;
        isrtable[11] = cast(ulong)&isr_11;
        isrtable[12] = cast(ulong)&isr_12;
        isrtable[13] = cast(ulong)&isr_13;
        isrtable[14] = cast(ulong)&isr_14;
        isrtable[16] = cast(ulong)&isr_16;
        isrtable[17] = cast(ulong)&isr_17;
        isrtable[18] = cast(ulong)&isr_18;
        isrtable[19] = cast(ulong)&isr_19;

        isrtable[32] = cast(ulong)&isr_32;
        isrtable[33] = cast(ulong)&isr_33;
        isrtable[34] = cast(ulong)&isr_34;
        isrtable[35] = cast(ulong)&isr_35;
        isrtable[36] = cast(ulong)&isr_36;
        isrtable[37] = cast(ulong)&isr_37;
        isrtable[38] = cast(ulong)&isr_38;
        isrtable[39] = cast(ulong)&isr_39;
        isrtable[40] = cast(ulong)&isr_40;
        isrtable[41] = cast(ulong)&isr_41;
        isrtable[42] = cast(ulong)&isr_42;
        isrtable[43] = cast(ulong)&isr_43;
        isrtable[44] = cast(ulong)&isr_44;
        isrtable[45] = cast(ulong)&isr_45;
        isrtable[46] = cast(ulong)&isr_46;
        isrtable[47] = cast(ulong)&isr_47;
        
        isrtable[127] = cast(ulong)&isr_127;
        isrtable[128] = cast(ulong)&isr_128;
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
        CPU.disableInterrupts();
        
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

    CPU.apic.write(APIC_EOI, 1);
}

template isr(int num)
{
    // Don't push a dummy error code for interrupts that provide one
    static if(num == 8 || num == 10 || num == 11 || num == 12 || num == 13 || num == 14)
    {
        const char[] isr = "

        extern(C) void isr_" ~ num.stringof ~ "()
        {
            asm
            {
                naked;
                \"push %%rbp\";
                \"mov $" ~ num.stringof ~ ", %%rbp\";
                \"jmp _isr_common_stub\";
            }
        }";
    }
    else
    {
        const char[] isr = "

        extern(C) void isr_" ~ num.stringof ~ "()
        {
            asm
            {
                naked;
                \"push $0\";
                \"push %%rbp\";
                \"mov $" ~ num.stringof ~ ", %%rbp\";
                \"jmp _isr_common_stub\";
            }
        }";
    }
}


mixin(isr!(0));
mixin(isr!(1));
mixin(isr!(2));
mixin(isr!(3));
mixin(isr!(4));
mixin(isr!(5));
mixin(isr!(6));
mixin(isr!(7));
mixin(isr!(8));
mixin(isr!(10));
mixin(isr!(11));
mixin(isr!(12));
mixin(isr!(13));
mixin(isr!(14));
mixin(isr!(16));
mixin(isr!(17));
mixin(isr!(18));
mixin(isr!(19));

mixin(isr!(32));
mixin(isr!(33));
mixin(isr!(34));
mixin(isr!(35));
mixin(isr!(36));
mixin(isr!(37));
mixin(isr!(38));
mixin(isr!(39));
mixin(isr!(40));
mixin(isr!(41));
mixin(isr!(42));
mixin(isr!(43));
mixin(isr!(44));
mixin(isr!(45));
mixin(isr!(46));
mixin(isr!(47));

mixin(isr!(127));
mixin(isr!(128));
