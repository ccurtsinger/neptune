
// short

module typeinfo.ti_short;

class TypeInfo_s : TypeInfo
{
    size_t tsize()
    {
	return short.sizeof;
    }
}

