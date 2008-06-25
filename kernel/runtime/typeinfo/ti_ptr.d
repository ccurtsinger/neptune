
// pointer

module typeinfo.ti_ptr;

class TypeInfo_P : TypeInfo
{
    size_t tsize()
    {
        return (void*).sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(void**)p1 < *cast(void**)p2)
            return -1;
        else if(*cast(void**)p1 > *cast(void**)p2)
            return 1;
            
        return 0;
    }
}
