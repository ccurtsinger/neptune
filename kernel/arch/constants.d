/**
 * Wrapper to import the native architecture's required support code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.constants;

version(arch_i586)
{
    public import kernel.arch.i586.constants;
}
else version(arch_x86_64)
{
    public import kernel.arch.x86_64.constants;
}
else
{
    static assert(false, "Unsupported architecture");
}
