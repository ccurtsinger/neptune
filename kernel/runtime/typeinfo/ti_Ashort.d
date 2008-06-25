
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
    
    int compare(void *p1, void *p2)
    {
        short[] s1 = *cast(short[]*)p1;
        short[] s2 = *cast(short[]*)p2;
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


// ushort[]

class TypeInfo_At : TypeInfo_As
{
    TypeInfo next()
    {
        return typeid(ushort);
    }
    
    int compare(void *p1, void *p2)
    {
        ushort[] s1 = *cast(ushort[]*)p1;
        ushort[] s2 = *cast(ushort[]*)p2;
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

// wchar[]

class TypeInfo_Au : TypeInfo_At
{
    TypeInfo next()
    {
        return typeid(wchar);
    }
}
