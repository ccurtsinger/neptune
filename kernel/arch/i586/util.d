/**
 * x86 architecture utilities
 *
 * Copyright: 2008 The Neptune Project
 */
 
module kernel.arch.i586.util;

template property(char[] name, char[] type, char[] reference, char[] get = "", char[] set = "")
{
    const char[] property = type ~ " " ~ name ~ "()
    {
        return " ~ reference ~ get ~ ";
    }

    void " ~ name ~ "(" ~ type ~ " value)
    {
        " ~ reference ~ " = value" ~ set ~ ";
    }";
}
