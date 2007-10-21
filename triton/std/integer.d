module std.integer;

/**
 * Return the number of digits in i
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
 * For digits above 9, A-F will be used, with the case determined by 'uc'
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
