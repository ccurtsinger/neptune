/**
 * Integer &lt;-&gt; String conversions
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module std.integer;

/**
 * Count the number of digits in i
 *
 * Params:
 *  i = value to count digits from
 *  radix = base to use when computing digit count
 * 
 * Returns: Number of digits in i with base radix
 */
size_t digits(size_t i, int radix = 10)
{
    if(i == 0)
        return 1;

    size_t d = 0;

    while(i > 0)
    {
        i -= i%radix;
        i /= radix;
        d++;
    }

    return d;
}

void puti(void function(char) putc, size_t i, size_t radix = 10, bool uc = true, size_t len = 0, char padchar = '0', bool pzero = true)
{
    if(len > 0)
    {
        size_t d = digits(i, radix);
        
        for(;d<len; d++)
        {
            putc(padchar);
        }
    }
    
    if(i > 0)
    {
        size_t value = i%radix;
        i -= value;
        i /= radix;
        
        puti(putc, i, radix, uc, 0, '0', false);
        
        if(value < 10)
            putc('0' + value);
        else if(uc)
            putc('A' + value - 10);
        else
            putc('a' + value - 10);
    }
    else if(pzero)
    {
        putc('0');
    }
}
