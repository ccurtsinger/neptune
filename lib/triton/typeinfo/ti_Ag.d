
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
    
    int compare(void *p1, void *p2)
    {
        byte[] s1 = *cast(byte[]*)p1;
        byte[] s2 = *cast(byte[]*)p2;
        size_t len = s1.length;

        if(s1.length < s2.length)
            return -1;
        else if(s1.length > s2.length)
            return 1;

        for (size_t u = 0; u < len; u++)
        {
            if(s1[u] < s2[u])
                return -1;
            else if(s1[u] > s2[u])
                return 1;
        }
            
        return 0;
    }
}


// ubyte[]

class TypeInfo_Ah : TypeInfo_Ag
{
    TypeInfo next()
    {
        return typeid(ubyte);
    }
    
    int compare(void *p1, void *p2)
    {
        ubyte[] s1 = *cast(ubyte[]*)p1;
        ubyte[] s2 = *cast(ubyte[]*)p2;
        size_t len = s1.length;

        if(s1.length < s2.length)
            return -1;
        else if(s1.length > s2.length)
            return 1;

        for (size_t u = 0; u < len; u++)
        {
            if(s1[u] < s2[u])
                return -1;
            else if(s1[u] > s2[u])
                return 1;
        }
            
        return 0;
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


