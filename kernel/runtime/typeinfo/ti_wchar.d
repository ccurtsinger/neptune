
module typeinfo.ti_wchar;

class TypeInfo_u : TypeInfo
{
    size_t tsize()
    {
        return wchar.sizeof;
    }
    
    void[] init()
    {   static wchar c;

        return (cast(wchar *)&c)[0 .. 1];
    }
}
