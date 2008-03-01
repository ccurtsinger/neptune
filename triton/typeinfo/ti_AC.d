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
}
