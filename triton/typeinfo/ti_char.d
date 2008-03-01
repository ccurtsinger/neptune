
module typeinfo.ti_char;

class TypeInfo_a : TypeInfo
{
    size_t tsize()
    {
        return char.sizeof;
    }

    void[] init()
    {   static char c;

        return (cast(char *)&c)[0 .. 1];
    }
}
