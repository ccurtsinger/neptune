module loader.util;

void enablePAE()
{
    asm
    {
        "mov %%cr4, %%eax";
        "or $0x20, %%eax";
        "mov %%eax, %%cr4";
    }
}

void enableWP()
{
    asm
    {
        "mov %%cr0, %%eax";
        "bts $16, %%eax";
        "mov %%eax, %%cr0";
    }
}

void installPaging(uint L4)
{
    asm
    {
        "mov %[L4], %%eax" : : [L4] "Nd" L4;
        "mov %%eax, %%cr3";
    }
}

void enableLongMode()
{
    asm
    {
        "mov $0xC0000080, %%ecx";
        "rdmsr";
        "bts $8, %%eax";
        "wrmsr";
    }
}

void enablePaging()
{
    asm
    {
        "mov %%cr0, %%eax";
        "bts $31, %%eax";
        "mov %%eax, %%cr0";
    }
}
