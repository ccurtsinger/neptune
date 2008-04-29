
// float

module typeinfo.ti_float;

class TypeInfo_f : TypeInfo
{
    size_t tsize()
    {
        return float.sizeof;
    }
    
    void[] init()
    {   static float r;

        return (cast(float *)&r)[0 .. 1];
    }
}
