
// void

module typeinfo.ti_void;

class TypeInfo_v : TypeInfo
{
    size_t tsize()
    {
        return void.sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(byte*)p1 < *cast(byte*)p2)
            return -1;
        else if(*cast(byte*)p1 > *cast(byte*)p2)
            return 1;
            
        return 0;
    }
}
