
// cfloat

module typeinfo.ti_cfloat;

class TypeInfo_q : TypeInfo
{
    size_t tsize()
    {
        return cfloat.sizeof;
    }
    
    void[] init()
    {   static cfloat r;

        return (cast(cfloat *)&r)[0 .. 1];
    }
}
