
module typeinfo.ti_Ag;

import std.mem;

// byte[]

class TypeInfo_Ag : TypeInfo
{
    size_t tsize()
    {
        return (byte[]).sizeof;
    }

    TypeInfo next()
    {
        return typeid(byte);
    }
}


// ubyte[]

class TypeInfo_Ah : TypeInfo_Ag
{
    TypeInfo next()
    {
        return typeid(ubyte);
    }
}

// void[]

class TypeInfo_Av : TypeInfo_Ah
{
    TypeInfo next()
    {
        return typeid(void);
    }
}

// bool[]

class TypeInfo_Ab : TypeInfo_Ah
{
    TypeInfo next()
    {
        return typeid(bool);
    }
}

// char[]

class TypeInfo_Aa : TypeInfo_Ag
{
    TypeInfo next()
    {
        return typeid(char);
    }
}


