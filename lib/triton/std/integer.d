/**
 * Integer to string conversions
 *
 * Copyright: 2008 The Neptune Project
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
size_t digits(size_t i, size_t base = 10)
{
    if(i == 0)
        return 1;

    size_t d = 0;

    while(i > 0)
    {
        i -= i%base;
        i /= base;
        d++;
    }

    return d;
}

char[] itoa(size_t value, char[] buf, size_t base = 10)
{
    int i = buf.length-1;
    int end = buf.length - digits(value, base);
    
    if(end < 0)
        end = 0;
    
    while(i >= 0)
    { 
        size_t digit = value % base;
        value -= digit;
        value /= base;
        
        buf[i] = digit < 10 ? '0'+digit : 'A'+digit-10;
        i--;
    }
    
    return buf[end..length];
}
