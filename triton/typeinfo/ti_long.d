
// long

module typeinfo.ti_long;

class TypeInfo_l : TypeInfo
{
    size_t tsize()
    {
	return long.sizeof;
    }
}

