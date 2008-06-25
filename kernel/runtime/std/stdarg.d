/**
 * Variable argument support code
 * 
 * Derived from work by Walter Bright (www.digitalmars.com),
 * Hauke Duden, and David Friedman
 *
 * Copyright: 2008 The Neptune Project
 */

module std.stdarg;

version (GNU) {
    // va_list might be a pointer, but assuming so is not portable.
    private import gcc.builtins;
    alias __builtin_va_list va_list;
    
    // va_arg is handled magically by the compiler
} else {
    alias void* va_list;
}

template va_arg(T)
{
    T va_arg(inout va_list _argptr)
    {
	/*
	T arg = *cast(T*)_argptr;
	_argptr = _argptr + ((T.sizeof + int.sizeof - 1) & ~(int.sizeof - 1));
	return arg;
	*/
	T t; return t;
    }
}

private import c.stdarg;
/* The existence of std.stdarg.va_copy isn't standard.  Prevent
   conflicts by using '__'. */
alias c.stdarg.va_copy __va_copy;
