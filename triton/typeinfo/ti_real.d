
// real

module typeinfo.ti_real;

class TypeInfo_e : TypeInfo
{
    size_t tsize()
    {
        return real.sizeof;
    }

    void[] init()
    {   static real r;

        return (cast(real *)&r)[0 .. 1];
    }
}
