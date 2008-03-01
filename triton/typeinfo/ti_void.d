
// void

module typeinfo.ti_void;

class TypeInfo_v : TypeInfo
{
    size_t tsize()
    {
        return void.sizeof;
    }
}
