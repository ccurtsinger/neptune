/**
 * String conversion utilities
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
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
