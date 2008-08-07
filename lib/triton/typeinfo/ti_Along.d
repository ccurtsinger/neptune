
module typeinfo.ti_Along;

//private import tango.stdc.string;
import std.mem;

// long[]

class TypeInfo_Al : TypeInfo
{
    size_t tsize()
    {
        return (long[]).sizeof;
    }

    TypeInfo next()
    {
        return typeid(long);
    }
}


// ulong[]

class TypeInfo_Am : TypeInfo_Al
{
    TypeInfo next()
    {
        return typeid(ulong);
    }
}
