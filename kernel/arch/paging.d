/**
 * Wrapper to import the native architecture's required paging code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.paging;

version(arch_i586)
{
    public import kernel.arch.i586.paging;
}
else version(arch_x86_64)
{
    public import kernel.arch.x86_64.paging;
}
else
{
    static assert(false, "Unsupported architecture");
}
