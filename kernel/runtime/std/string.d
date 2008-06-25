/**
 * String utility functions
 *
 * Copyright: 2008 The Neptune Project
 */
 
module std.string;

/**
 * Convert a standard C null-terminated string to a D string
 *
 * Params:
 *  str = string to convert
 *
 * Returns: D style string representation of str
 */
public char[] ctodstr(char* str)
{
    return str[0..cstrlen(str)];
}

/**
 * Determine the length of a C style null-terminated string
 *
 * Params:
 *  str = string to determine the length of
 *
 * Return: length of the C-style string
 */
public size_t cstrlen(char* str)
{
    int i=0;
    
    while(str[i] != '\0')
    {
        i++;
    }
    
    return i;
}

/**
 * Find the first occurrance (from offset) of needle in haystack
 *
 * Params:
 *  haystack = string to scan for occurrances
 *  needle = string to search for
 *  offset = minimum index to begin search
 *
 * Returns: -1 or the index of needle in haystack
 */
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

/**
 * Split a string into chunks bya  delimiter
 *
 * Parmas:
 *  delimiter = string to split on
 *  str = string to split
 *  limit = maximum number of chunks to return
 *
 * Returns: Array of string chunks (slices of str)
 */
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
