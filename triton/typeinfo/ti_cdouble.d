
// cdouble

module typeinfo.ti_cdouble;

class TypeInfo_r : TypeInfo
{
    size_t tsize()
    {
        return cdouble.sizeof;
    }

    void[] init()
    {   static cdouble r;

        return (cast(cdouble *)&r)[0 .. 1];
    }
}
