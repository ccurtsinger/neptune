
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
    
    int compare(void *p1, void *p2)
    {
        long[] s1 = *cast(long[]*)p1;
        long[] s2 = *cast(long[]*)p2;
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


// ulong[]

class TypeInfo_Am : TypeInfo_Al
{
    TypeInfo next()
    {
        return typeid(ulong);
    }
    
    int compare(void *p1, void *p2)
    {
        ulong[] s1 = *cast(ulong[]*)p1;
        ulong[] s2 = *cast(ulong[]*)p2;
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
