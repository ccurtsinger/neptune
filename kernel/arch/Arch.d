module kernel.arch.Arch;

import std.type;

alias void function() isr_t;

const paddr_t LINEAR_MEM_BASE = cast(paddr_t)0xFFFF830000000000;

vaddr_t ptov(paddr_t address)
{
    return cast(vaddr_t)(address + LINEAR_MEM_BASE);
}

paddr_t vtop(vaddr_t address)
{
    return cast(paddr_t)address - LINEAR_MEM_BASE;
}
