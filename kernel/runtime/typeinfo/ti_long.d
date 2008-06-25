
// long

module typeinfo.ti_long;

class TypeInfo_l : TypeInfo
{
    size_t tsize()
    {
        return long.sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(long*)p1 < *cast(long*)p2)
            return -1;
        else if(*cast(long*)p1 > *cast(long*)p2)
            return 1;
            
        return 0;
    }
}

