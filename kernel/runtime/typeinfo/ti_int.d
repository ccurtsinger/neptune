
// int

module typeinfo.ti_int;

class TypeInfo_i : TypeInfo
{
    size_t tsize()
    {
        return int.sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(int*)p1 < *cast(int*)p2)
            return -1;
        else if(*cast(int*)p1 > *cast(int*)p2)
            return 1;
            
        return 0;
    }
}

