/**
 * Wrapper to import the native architecture's required support code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.native;

version(arch_i586)
{
    public import kernel.arch.i586.arch;
    public import kernel.arch.i586.constants;
    public import kernel.arch.i586.paging;
    public import kernel.arch.i586.registers;
    public import kernel.arch.i586.descriptors;
    public import kernel.arch.i586.interrupts;
    public import kernel.arch.i586.screen;
}
else version(arch_x86_64)
{
    static assert(false, "TODO: implement x86_64 architecture support");
}
else
{
    static assert(false, "Unsupported architecture");
}
