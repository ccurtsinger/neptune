module kernel.arch.i586.util;

template pusha()
{
    const char[] pusha = "
    asm
    {
        \"push %%ebp\";
        \"push %%edi\";
        \"push %%esi\";
        \"push %%edx\";
        \"push %%ecx\";
        \"push %%ebx\";
        \"push %%eax\";
        \"pushf\";
    }";
}

template popa()
{
    const char[] popa = "
    asm
    {
        \"popf\";
        \"pop %%eax\";
        \"pop %%ebx\";
        \"pop %%ecx\";
        \"pop %%edx\";
        \"pop %%esi\";
        \"pop %%edi\";
        \"pop %%ebp\";
    }";
}

void cli()
{
    asm{"cli";}
}

void sti()
{
    asm{"sti";}
}
