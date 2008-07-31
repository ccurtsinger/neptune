/**
 * String conversion utilities
 *
 * Copyright: 2008 The Neptune Project
 */
 
module std.string;

public char[] ctodstr(char* str)
{
    return str[0..cstrlen(str)];
}

public size_t cstrlen(char* str)
{
    int i=0;
    
    while(str[i] != '\0')
    {
        i++;
    }
    
    return i;
}
