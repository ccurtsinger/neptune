
// creal

module typeinfo.ti_creal;

class TypeInfo_c : TypeInfo
{
    size_t tsize()
    {
        return creal.sizeof;
    }
    
    void[] init()
    {   static creal r;

        return (cast(creal *)&r)[0 .. 1];
    }
}
