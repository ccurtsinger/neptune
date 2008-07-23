/**
 * Register access functions
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.x86_64.registers;

version(arch_x86_64):

template registerProperty(char[] name)
{
    const char[] registerProperty = "static size_t " ~ name ~ "() {
        size_t value;
        asm
        {
            \"mov %%" ~ name ~ ", %[value]\" : [value] \"=a\" value;
        }
        return value;
    }

    static void " ~ name ~ "(size_t value) {
        asm
        {
            \"mov %[value], %%" ~ name ~ "\" : : [value] \"a\" value;
        }
    }";
}

mixin(registerProperty!("cr0"));
mixin(registerProperty!("cr1"));
mixin(registerProperty!("cr2"));
mixin(registerProperty!("cr3"));
mixin(registerProperty!("cr4"));
mixin(registerProperty!("ss"));

mixin(registerProperty!("rsp"));
mixin(registerProperty!("rbp"));
mixin(registerProperty!("rax"));
mixin(registerProperty!("rbx"));
mixin(registerProperty!("rcx"));
mixin(registerProperty!("rdx"));
mixin(registerProperty!("rdi"));
mixin(registerProperty!("rsi"));
mixin(registerProperty!("r8"));
mixin(registerProperty!("r9"));
mixin(registerProperty!("r10"));
mixin(registerProperty!("r11"));
mixin(registerProperty!("r12"));
mixin(registerProperty!("r13"));
mixin(registerProperty!("r14"));
mixin(registerProperty!("r15"));
