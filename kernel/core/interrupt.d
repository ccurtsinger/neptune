/**
 * Interrupt handling code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core.interrupt;

import util.arch.cpu;
import util.arch.idt;
import util.arch.apic;
import util.arch.descriptor;

import std.port;
import std.stdio;
import std.context;

import kernel.core.env;
import kernel.core.event;

char[][256] interrupt_events;

public void interrupt_setup()
{
    CPU.idt.init(0xFFFD);
    
    set_isr(0, &isr_0);
    set_isr(1, &isr_1);
    set_isr(2, &isr_2);
    set_isr(3, &isr_3);
    set_isr(4, &isr_4);
    set_isr(5, &isr_5);
    set_isr(6, &isr_6);
    set_isr(7, &isr_7);
    set_isr(8, &isr_8);
    set_isr(10, &isr_10);
    set_isr(11, &isr_11);
    set_isr(12, &isr_12);
    set_isr(13, &isr_13);
    set_isr(14, &isr_14, 0, 1);
    set_isr(16, &isr_16);
    set_isr(17, &isr_17);
    set_isr(18, &isr_18);
    set_isr(19, &isr_19);
    
    set_isr(32, &isr_32);
    set_isr(33, &isr_33);
    set_isr(34, &isr_34);
    set_isr(35, &isr_35);
    set_isr(36, &isr_36);
    set_isr(37, &isr_37);
    set_isr(38, &isr_38);
    set_isr(39, &isr_39);
    set_isr(40, &isr_40);
    set_isr(41, &isr_41);
    set_isr(42, &isr_42);
    set_isr(43, &isr_43);
    set_isr(44, &isr_44);
    set_isr(45, &isr_45);
    set_isr(46, &isr_46);
    set_isr(47, &isr_47);
    
    set_isr(127, &isr_127);
    set_isr(128, &isr_128, 3);
    
    for(size_t i=0; i<interrupt_events.length; i++)
    {
        interrupt_events[i].length = 0;
    }
    
    interrupt_events[14] = "int.pagefault";
    interrupt_events[39] = "irq.ignore";
    interrupt_events[127] = "dev.timer";
    
    CPU.idt.install();
}

public void set_isr(size_t interrupt, void* isr, size_t privilege = 0, size_t ist = 0)
{
    GateDescriptor* d = CPU.idt[interrupt];
    
    d.target = cast(size_t)isr;
    d.selector = 0x08;
    d.type = DescriptorType.INTERRUPT;
    d.privilege = privilege;
    d.stack = ist;
    d.present = true;
}

extern(C) void _isr_common_stub()
{
    asm
    {
        naked;
        // Save register state
        "push %%r15";
        "push %%r14";
        "push %%r13";
        "push %%r12";
        "push %%r11";
        "push %%r10";
        "push %%r9";
        "push %%r8";
        "push %%rdi";
        "push %%rsi";
        "push %%rdx";
        "push %%rcx";
        "push %%rbx";
        "push %%rax";
        
        // Set parameters for interrupt handler
        // rbp holds the interrupt number, and the stack points to the interrupt context
        "mov %%rbp, %%rdi";
        "mov %%rsp, %%rsi";
        "lea _common_interrupt(%%rip), %%rax";
        "call *%%rax";
        
        // Restore register state
        "pop %%rax";
        "pop %%rbx";
        "pop %%rcx";
        "pop %%rdx";
        "pop %%rsi";
        "pop %%rdi";
        "pop %%r8";
        "pop %%r9";
        "pop %%r10";
        "pop %%r11";
        "pop %%r12";
        "pop %%r13";
        "pop %%r14";
        "pop %%r15";
        "pop %%rbp";
        
        // Shift the stack beyond the pushed error code and resume execution
        "add $8, %%rsp";
        "iretq";
    }
}

extern(C) void _common_interrupt(ulong interrupt, Context* stack)
{
    if(interrupt_events[interrupt].length != 0)
    {
        root.raiseEvent(interrupt_events[interrupt], new InterruptEventSource(stack));
    }
    else
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

extern(C) void isr_128()
{
    asm
    {
        naked;
        "call test_syscall";
        "iretq";
    }
}
