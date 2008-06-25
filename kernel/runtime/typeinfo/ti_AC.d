module typeinfo.ti_AC;

// Object[]

class TypeInfo_AC : TypeInfo
{
    size_t tsize()
    {
        return (Object[]).sizeof;
    }
    
    TypeInfo next()
    {
        return typeid(Object);
    }
    
    int compare(void *p1, void *p2)
    {
        Object[] s1 = *cast(Object[]*)p1;
        Object[] s2 = *cast(Object[]*)p2;
        ptrdiff_t c;

        c = cast(ptrdiff_t)s1.length - cast(ptrdiff_t)s2.length;
        
        if (c == 0)
        {
            for (size_t u = 0; u < s1.length; u++)
            {
                Object o1 = s1[u];
                Object o2 = s2[u];

                if (o1 is o2)
                    continue;

                // Regard null references as always being "less than"
                if (o1)
                {
                    if (!o2)
                    {   c = 1;
                        break;
                    }
                    c = o1.opCmp(o2);
                    if (c)
                        break;
                }
                else
                {
                    c = -1;
                    break;
                }
            }
        }
        if (c < 0)
            c = -1;
        else if (c > 0)
            c = 1;
        return c;
    }
}
