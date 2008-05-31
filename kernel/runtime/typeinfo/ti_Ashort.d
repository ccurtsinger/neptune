
module typeinfo.ti_Ashort;

//private import tango.stdc.string;
import std.mem;

// short[]

class TypeInfo_As : TypeInfo
{
    size_t tsize()
    {
        return (short[]).sizeof;
    }

    TypeInfo next()
    {
        return typeid(short);
    }
}


// ushort[]

class TypeInfo_At : TypeInfo_As
{
    TypeInfo next()
    {
        return typeid(ushort);
    }
}

// wchar[]

class TypeInfo_Au : TypeInfo_At
{
    TypeInfo next()
    {
        return typeid(wchar);
    }
}
