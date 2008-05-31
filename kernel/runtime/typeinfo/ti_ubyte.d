
// ubyte

module typeinfo.ti_ubyte;

class TypeInfo_h : TypeInfo
{
    size_t tsize()
    {
        return ubyte.sizeof;
    }
}

class TypeInfo_b : TypeInfo_h
{

}
