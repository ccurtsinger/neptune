
// uint

module typeinfo.ti_uint;

class TypeInfo_k : TypeInfo
{
    size_t tsize()
    {
	return uint.sizeof;
    }
}

