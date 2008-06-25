
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
    
    int compare(void *p1, void *p2)
    {
        int[] s1 = *cast(int[]*)p1;
        int[] s2 = *cast(int[]*)p2;
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

// uint[]

class TypeInfo_Ak : TypeInfo_Ai
{
    TypeInfo next()
    {
        return typeid(uint);
    }
    
    int compare(void *p1, void *p2)
    {
        uint[] s1 = *cast(uint[]*)p1;
        uint[] s2 = *cast(uint[]*)p2;
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

// dchar[]

class TypeInfo_Aw : TypeInfo_Ak
{
    TypeInfo next()
    {
        return typeid(dchar);
    }
}

