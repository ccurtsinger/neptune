/**
 * Interrupt handler (ISR) generation and definition
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.interrupts;

version(arch_i586):

template isr_ref(int n = 0)
{
    static if(n < 256)
    {
        const char[] isr_ref = "idt[" ~ n.stringof ~ "].offset = cast(size_t)&isr_" ~ n.stringof ~ ";" ~ isr_ref!(n+1);
    }
    else
    {
        const char[] isr_ref = "";
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

template define_isrs(int n = 0)
{
    static if(n < 256)
    {
        const char[] define_isrs = "mixin(isr!(" ~ n.stringof ~ "));" ~ define_isrs!(n+1);
    }
    else
    {
        const char[] define_isrs = "";
    }
}

mixin(define_isrs!());
