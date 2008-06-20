/**
 * Interrupt handler (ISR) generation and definition
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.interrupts;

import kernel.arch.i586.constants;
import kernel.arch.i586.descriptors;
import kernel.arch.i586.pic;
import kernel.arch.i586.registers;

import kernel.syscall;

import std.stdio;

version(arch_i586):

Descriptor[256] idt;
InterruptHandler[256] int_handlers;

void setup_interrupts()
{
    // Exceptions
    set_isr(0, &isr_0, 3);
    set_isr(1, &isr_1, 3);
    set_isr(2, &isr_2, 3);
    set_isr(3, &isr_3, 3);
    set_isr(4, &isr_4, 3);
    set_isr(5, &isr_5, 3);
    set_isr(6, &isr_6, 3);
    set_isr(7, &isr_7, 3);
    set_isr(8, &isr_8, 3);
    set_isr(10, &isr_10, 3);
    set_isr(11, &isr_11, 3);
    set_isr(12, &isr_12, 3);
    set_isr(13, &isr_13, 3);
    set_isr(14, &isr_14, 3);
    set_isr(16, &isr_16, 3);
    set_isr(17, &isr_17, 3);
    set_isr(18, &isr_18, 3);
    set_isr(19, &isr_19, 3);
    
    // IRQs
    set_isr(32, &isr_32, 0);
    set_isr(33, &isr_33, 0);
    set_isr(34, &isr_34, 0);
    set_isr(35, &isr_35, 0);
    set_isr(36, &isr_36, 0);
    set_isr(37, &isr_37, 0);
    set_isr(38, &isr_38, 0);
    set_isr(39, &isr_39, 0);
    set_isr(40, &isr_40, 0);
    set_isr(41, &isr_41, 0);
    set_isr(42, &isr_42, 0);
    set_isr(43, &isr_43, 0);
    set_isr(44, &isr_44, 0);
    set_isr(45, &isr_45, 0);
    set_isr(46, &isr_46, 0);
    set_isr(47, &isr_47, 0);

    // Syscalls
    set_isr(128, &isr_128, 3);
    set_isr(129, &isr_129, 3);
    set_isr(130, &isr_130, 3);
    
    int_handlers[0] = InterruptHandler("divide by zero exception");
    int_handlers[1] = InterruptHandler("debug exception");
    int_handlers[2] = InterruptHandler("non-maskable interrupt");
    int_handlers[3] = InterruptHandler("breakpoint exception");
    int_handlers[4] = InterruptHandler("overflow exception");
    int_handlers[5] = InterruptHandler("bound-range exception");
    int_handlers[6] = InterruptHandler("invalid opcode");
    int_handlers[7] = InterruptHandler("device not available");
    int_handlers[8] = InterruptHandler("double fault");
    int_handlers[10] = InterruptHandler("invalid TSS");
    int_handlers[11] = InterruptHandler("segment not present");
    int_handlers[12] = InterruptHandler("stack exception");
    int_handlers[13] = InterruptHandler("general protection fault");
    int_handlers[14] = InterruptHandler("page fault");
    int_handlers[16] = InterruptHandler("x87 floating point exception");
    int_handlers[17] = InterruptHandler("alignment check exception");
    int_handlers[18] = InterruptHandler("machine check exception");
    int_handlers[19] = InterruptHandler("SIMD floating point exception");
    
    lidt(idt);
    
    remap_pic(32, 0xFFFF);
}

void set_isr(size_t interrupt, void* handler, size_t dpl)
{
    idt[interrupt].clear();
    idt[interrupt].present = true;
    idt[interrupt].dpl = dpl;
    idt[interrupt].type = DescriptorType.INTERRUPT_GATE;
    idt[interrupt].selector = GDTSelector.KERNEL_CODE;
    idt[interrupt].offset = cast(size_t)handler;
}

extern(C) void common_interrupt(int interrupt, int error, Context* context)
{
    if(!int_handlers[interrupt].set || !int_handlers[interrupt](context))
    {
        writefln("interrupt %u: %s", interrupt, int_handlers[interrupt].error);
        writefln("  error: %02#x", error);
        writefln("   %%eip: %08#x", context.eip);
        writefln("   %%esp: %08#x", context.esp);
        writefln("   %%ebp: %08#x", context.ebp);
        writefln("    %%cs: %02#x", context.cs);
        writefln("    %%ss: %02#x", context.ss);
        writefln("   %%eax: %08#x", context.eax);
        writefln("   %%ebx: %08#x", context.ebx);
        writefln("   %%ecx: %08#x", context.ecx);
        writefln("   %%edx: %08#x", context.edx);
        writefln("   %%esi: %08#x", context.esi);
        writefln("   %%edi: %08#x", context.edi);
        writefln("   %%cr2: %08#x", cr2);
        writefln("  flags: %08#x", context.flags);
    
        for(;;){}
    }
}

struct Context
{
    uint eax;
    uint ebx;
    uint ecx;
    uint edx;
    uint esi;
    uint edi;
    uint ebp;
    uint eip;
    uint cs;
    uint flags;
    uint esp;
    uint ss;
}

struct InterruptHandler
{
    bool set = false;
    char[] error = "unhandled interrupt";
    bool function(Context*) handler = null;
    
    public static InterruptHandler opCall(char[] error)
    {
        InterruptHandler i;
        i.error = error;
        return i;
    }
    
    public static InterruptHandler opCall(bool function(Context*) handler, char[] error)
    {
        InterruptHandler i;
        i.handler = handler;
        i.error = error;
        i.set = true;
        return i;
    }
    
    public bool opCall(Context* c)
    {
        assert(handler !is null, "Invoked null interrupt handler");
        
        return handler(c);
    }
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
                \"push %%edi\";
                \"mov 4(%%esp), %%edi\";
                \"mov %%ebp, 4(%%esp)\";
                \"push %%esi\";
                \"push %%edx\";
                \"push %%ecx\";
                \"push %%ebx\";
                \"push %%eax\";
                \"push %%esp\";
                \"push %%edi\";
                \"push $" ~ num.stringof ~ "\";
                \"call common_interrupt\";
                \"add $12, %%esp\";
                \"pop %%eax\";
                \"pop %%ebx\";
                \"pop %%ecx\";
                \"pop %%edx\";
                \"pop %%esi\";
                \"pop %%edi\";
                \"pop %%ebp\";
                \"iret\";
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
                \"push %%ebp\";
                \"push %%edi\";
                \"push %%esi\";
                \"push %%edx\";
                \"push %%ecx\";
                \"push %%ebx\";
                \"push %%eax\";
                \"push %%esp\";
                \"push $0\";
                \"push $" ~ num.stringof ~ "\";
                \"call common_interrupt\";
                \"add $12, %%esp\";
                \"pop %%eax\";
                \"pop %%ebx\";
                \"pop %%ecx\";
                \"pop %%edx\";
                \"pop %%esi\";
                \"pop %%edi\";
                \"pop %%ebp\";
                \"iret\";
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

extern(C) void isr_128()
{
    asm
    {
        naked;
        "jmp syscall_a";
        "iret";
    }
}

extern(C) void isr_129()
{
    asm
    {
        naked;
        "jmp syscall_b";
        "iret";
    }
}

extern(C) void isr_130()
{
    asm
    {
        naked;
        "jmp syscall_c";
        "iret";
    }
}
