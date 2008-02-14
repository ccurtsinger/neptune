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
extern(C) void itoa(size_t i, char* s, int radix = 10, bool uc = true)
{
    if(i == 0)
    {
        s[0] = '0';
        return;
    }

    size_t digit = digits(i, radix) - 1;
    size_t value;

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

version(x86_64)
{
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
}
