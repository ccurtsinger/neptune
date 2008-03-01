
// dchar

module typeinfo.ti_dchar;

class TypeInfo_w : TypeInfo
{
    size_t tsize()
    {
        return dchar.sizeof;
    }
    
    void[] init()
    {   static dchar c;

        return (cast(dchar *)&c)[0 .. 1];
    }
}
