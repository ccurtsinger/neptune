
// ubyte

module typeinfo.ti_ubyte;

class TypeInfo_h : TypeInfo
{
    size_t tsize()
    {
        return ubyte.sizeof;
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(ubyte*)p1 < *cast(ubyte*)p2)
            return -1;
        else if(*cast(ubyte*)p1 > *cast(ubyte*)p2)
            return 1;
            
        return 0;
    }
}

class TypeInfo_b : TypeInfo_h
{

}
