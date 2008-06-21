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

public int strpos(char[] haystack, char[] needle, size_t offset = 0)
{
    if(needle.length > haystack.length)
        return -1;
    
    for(int i=offset; i<haystack.length - needle.length + 1 ; i++)
    {
        if(haystack[i..i+needle.length] == needle)
            return i;
    }
    
    return -1;
}

public char[][] explode(char[] delimiter, char[] str, size_t limit = 0)
{
    char[][] ret;
    
    size_t base = 0;
    size_t top = 0;
    
    while(top < str.length)
    {
        top = strpos(str, delimiter, base);
        
        if(top == -1 || (limit != 0 && ret.length >= limit - 1))
            top = str.length;
            
        ret ~= str[base..top];
        base = top + 1;
    }
    
    return ret;
}
