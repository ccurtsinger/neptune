
// delegate

module typeinfo.ti_delegate;

alias void delegate(int) dg;

class TypeInfo_D : TypeInfo
{
    size_t tsize()
    {
        return dg.sizeof;
    }
}
