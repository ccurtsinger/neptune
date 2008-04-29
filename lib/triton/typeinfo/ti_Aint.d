
module typeinfo.ti_Aint;

//private import tango.stdc.string;
import std.mem;

// int[]

class TypeInfo_Ai : TypeInfo
{
    size_t tsize()
    {
        return (int[]).sizeof;
    }
    
    TypeInfo next()
    {
        return typeid(int);
    }
}

// uint[]

class TypeInfo_Ak : TypeInfo_Ai
{
    TypeInfo next()
    {
        return typeid(uint);
    }
}

// dchar[]

class TypeInfo_Aw : TypeInfo_Ak
{
    TypeInfo next()
    {
        return typeid(dchar);
    }
}

