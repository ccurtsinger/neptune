/**
 * Integer &lt;-&gt; String conversions
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module std.integer;

/**
 * Convert 'i' to a string in 's' using base 'radix'
 *
 * Params:
 *  i = value to convert
 *  s = memory to use for the string
 *  radix = base to convert with
 *  uc = If true, A-Z will be used for values over 9, otherwise a-z will be used
 */
extern(C) void itoa(ulong i, char* s, int radix = 10, bool uc = true)
{
    if(i == 0)
    {
        s[0] = '0';
        return;
    }

    long digit = digits(i, radix) - 1;
    ulong value;

    while(i > 0)
    {
        value = i % radix;
        i -= value;
        i /= radix;

        if(value < 10)
            s[digit] = '0' + value;
        else if(uc)
            s[digit] = 'A' + value - 10;
        else
            s[digit] = 'a' + value - 10;

        digit--;
    }
}

/**
 * Count the number of digits in i
 *
 * Params:
 *  i = value to count digits from
 *  radix = base to use when computing digit count
 * 
 * Returns: Number of digits in i with base radix
 */
size_t digits(ulong i, int radix = 10)
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

char[] toString(ulong i, int radix = 10, bool uc = true, int min_length = 0, char padchar = ' ')
{
    size_t length = digits(i, radix);
    
    if(length < min_length)
        length = min_length;
    
    char[] str = new char[length];
    
    for(size_t index=length; index>0; index--)
    {
        if(i == 0 && index < length)
            str[index-1] = padchar;
        else if(i == 0)
            str[index-1] = '0';
        else
        {
            ulong d = i%radix;
            i -= d;
            i /= radix;
            
            if(d < 10)
                str[index-1] = '0' + d;
            else if(uc)
                str[index-1] = 'A' + (d - 10);
            else
                str[index-1] = 'a' + (d - 10);
        }
    }
    
    return str;
}

char[] intToString(long i, int radix = 10, bool uc = true, int min_length = 0, char padchar = ' ')
{
    bool sign = false;
    
    size_t length = 0;
    
    if(i < 0)
    {
        i = -i;
        sign = true;
        length++;
    }
    
    size_t digit_count = digits(cast(ulong)i, radix);
    length += digit_count;
    
    if(length < min_length)
        length = min_length;
    
    char[] str = new char[length];
    
    if(sign)
        str[0] = '-';
    
    for(size_t index=length; (sign && index > 1) || (!sign && index>0); index--)
    {
        if(i == 0 && index < length)
            str[index-1] = padchar;
        else if(i == 0)
            str[index-1] = 0;
        else
        {
            ulong d = i%radix;
            i -= d;
            i /= radix;
            
            if(d < 10)
                str[index-1] = '0' + d;
            else if(uc)
                str[index-1] = 'A' + (d - 10);
            else
                str[index-1] = 'a' + (d - 10);
        }
        
        if(sign && index == length - digit_count)
            str[index-1] = '-';
    }
    
    return str;
}
