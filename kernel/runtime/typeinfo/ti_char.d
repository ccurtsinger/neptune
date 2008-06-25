
module typeinfo.ti_char;

class TypeInfo_a : TypeInfo
{
    size_t tsize()
    {
        return char.sizeof;
    }

    void[] init()
    {
        static char c;

        return (cast(char *)&c)[0 .. 1];
    }
    
    int compare(void *p1, void *p2)
    {
        if(*cast(char*)p1 < *cast(char*)p2)
            return -1;
        else if(*cast(char*)p1 > *cast(char*)p2)
            return 1;
            
        return 0;
    }
}
