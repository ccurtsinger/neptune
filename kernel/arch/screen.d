/**
 * Wrapper to import the native architecture's required printing code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.screen;

version(arch_i586)
{
    public import kernel.arch.i586.screen;
}
else version(arch_x86_64)
{
    public import kernel.arch.x86_64.screen;
}
else
{
    static assert(false, "Unsupported architecture");
}
