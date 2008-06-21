
// short

module typeinfo.ti_short;

class TypeInfo_s : TypeInfo
{
    size_t tsize()
    {
        return short.sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(short*)p1 < *cast(short*)p2)
            return -1;
        else if(*cast(short*)p1 > *cast(short*)p2)
            return 1;
            
        return 0;
    }
}

