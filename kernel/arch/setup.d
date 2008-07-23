/**
 * Wrapper to import the native architecture's required setup code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.setup;

version(arch_i586)
{
    public import kernel.arch.i586.setup;
}
else version(arch_x86_64)
{
    public import kernel.arch.x86_64.setup;
}
else
{
    static assert(false, "Unsupported architecture");
}
