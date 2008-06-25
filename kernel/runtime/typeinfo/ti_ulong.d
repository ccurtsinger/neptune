
// ulong

module typeinfo.ti_ulong;

class TypeInfo_m : TypeInfo
{
    size_t tsize()
    {
        return ulong.sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(ulong*)p1 < *cast(ulong*)p2)
            return -1;
        else if(*cast(ulong*)p1 > *cast(ulong*)p2)
            return 1;
            
        return 0;
    }
}

