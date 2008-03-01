
// pointer

module typeinfo.ti_ptr;

class TypeInfo_P : TypeInfo
{
    size_t tsize()
    {
        return (void*).sizeof;
    }
}
