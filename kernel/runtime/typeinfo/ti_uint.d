
// uint

module typeinfo.ti_uint;

class TypeInfo_k : TypeInfo
{
    size_t tsize()
    {
        return uint.sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(uint*)p1 < *cast(uint*)p2)
            return -1;
        else if(*cast(uint*)p1 > *cast(uint*)p2)
            return 1;
            
        return 0;
    }
}

