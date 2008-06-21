
// byte

module typeinfo.ti_byte;

class TypeInfo_g : TypeInfo
{
    size_t tsize()
    {
        return byte.sizeof;
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

