
// ulong

module typeinfo.ti_ulong;

class TypeInfo_m : TypeInfo
{
    size_t tsize()
    {
	return ulong.sizeof;
    }
}

