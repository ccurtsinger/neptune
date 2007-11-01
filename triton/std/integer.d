/**
 * Integer &lt;-&gt; String conversions
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
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
extern(C) long digits(ulong i, int radix = 10)
{
    if(i == 0)
        return 1;

    long d = 0;

    while(i > 0)
    {
        i -= i%radix;
        i /= radix;
        d++;
    }

    return d;
}

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
