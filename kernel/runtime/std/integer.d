/**
 * Integer conversions
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

/**
 * Convert an unsigned integer to a string in a given base
 *
 * Params:
 *  value = integer to convert
 *  buf = character array to store digits in
 *  base = base to convert integer to
 *
 * Returns: reference to the converted integer (buf) sliced to the final length
 */
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
        
        buf[i] = digit < 10 ? '0'+digit : 'a'+digit-10;
        i--;
    }
    
    return buf[end..length];
}
