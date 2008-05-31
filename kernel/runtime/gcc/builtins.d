/**
 * Definition for base language types
 * 
 * Copyright: 2008 David Friedman
 */

/**
  Declarations are automatically created by the compiler.  All
  declarations start with "__builtin_". Refer to _builtins.def in the
  GCC source for a list of functions.  Not all of the functions are
  supported.
 
  In addition to built-in functions, the following types are defined.
 
  $(TABLE 
  $(TR $(TD ___builtin_va_list)      $(TD The target's va_list type ))
  $(TR $(TD ___builtin_Clong  )      $(TD The D equivalent of the target's
                                           C "long" type ))
  $(TR $(TD ___builtin_Culong )      $(TD The D equivalent of the target's
                                           C "unsigned long" type ))
  $(TR $(TD ___builtin_machine_int ) $(TD Signed word-sized integer ))
  $(TR $(TD ___builtin_machine_uint) $(TD Unsigned word-sized integer ))
  $(TR $(TD ___builtin_pointer_int ) $(TD Signed pointer-sized integer ))
  $(TR $(TD ___builtin_pointer_uint) $(TD Unsigned pointer-sized integer ))
  )
 */

module gcc.builtins;
