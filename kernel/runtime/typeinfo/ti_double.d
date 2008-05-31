
// double

module typeinfo.ti_double;

class TypeInfo_d : TypeInfo
{
    size_t tsize()
    {
        return double.sizeof;
    }
    
    void[] init()
    {   static double r;

        return (cast(double *)&r)[0 .. 1];
    }
}

