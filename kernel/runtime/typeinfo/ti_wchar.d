
module typeinfo.ti_wchar;

class TypeInfo_u : TypeInfo
{
    size_t tsize()
    {
        return wchar.sizeof;
    }
    
    void[] init()
    {
        static wchar c;

        return (cast(wchar *)&c)[0 .. 1];
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(wchar*)p1 < *cast(wchar*)p2)
            return -1;
        else if(*cast(wchar*)p1 > *cast(wchar*)p2)
            return 1;
            
        return 0;
    }
}
