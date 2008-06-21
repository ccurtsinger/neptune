
// ushort

module typeinfo.ti_ushort;

class TypeInfo_t : TypeInfo
{
    size_t tsize()
    {
        return ushort.sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(ushort*)p1 < *cast(ushort*)p2)
            return -1;
        else if(*cast(ushort*)p1 > *cast(ushort*)p2)
            return 1;
            
        return 0;
    }
}

