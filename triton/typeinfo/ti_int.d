
// int

module typeinfo.ti_int;

class TypeInfo_i : TypeInfo
{
    size_t tsize()
    {
	return int.sizeof;
    }
}

