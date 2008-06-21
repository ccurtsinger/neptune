
// dchar

module typeinfo.ti_dchar;

class TypeInfo_w : TypeInfo
{
    size_t tsize()
    {
        return dchar.sizeof;
    }
    
    void[] init()
    {
        static dchar c;

        return (cast(dchar *)&c)[0 .. 1];
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(dchar*)p1 < *cast(dchar*)p2)
            return -1;
        else if(*cast(dchar*)p1 > *cast(dchar*)p2)
            return 1;
            
        return 0;
    }
}
