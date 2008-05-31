/**
 * Register access functions
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.registers;

version(arch_i586):

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

mixin(registerProperty!("esp"));
mixin(registerProperty!("ebp"));
mixin(registerProperty!("eax"));
mixin(registerProperty!("ebx"));
mixin(registerProperty!("ecx"));
mixin(registerProperty!("edx"));
mixin(registerProperty!("edi"));
mixin(registerProperty!("esi"));
