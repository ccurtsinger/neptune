module kernel.arch.native;

version(arch_i586)
{
    public import kernel.arch.i586.arch;
}
else version(arch_x86_64)
{
    static assert(false, "TODO: implement x86_64 architecture support");
}
else
{
    static assert(false, "Unsupported architecture");
}
