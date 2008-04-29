/**
 * Type defines for various architectures
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module type;

version(x86_64)
{
    alias ulong size_t;
    alias long  ptrdiff_t;
    alias size_t hash_t;
}
else version(i586)
{
    alias uint size_t;
    alias int  ptrdiff_t;
    alias size_t hash_t;
}
else
{
    static assert(false, "Unsupported version");
}
