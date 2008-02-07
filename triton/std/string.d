
module std.string;

char[][] explode(char[] str, char separator)
{
	size_t count = 1;
	
	foreach(char c; str)
	{
		if(c == separator)
			count++;
	}
	
	char[][] ret = new char[][count];
	
	size_t index = 0;
	size_t base = 0;
	
	foreach(size_t i, char c; str)
	{
		if(c == separator)
		{
			ret[index] = new char[i - base];
			ret[index][] = str[base..i];
			
			index++;
			base = i+1;
		}
	}
	
	ret[index] = new char[str.length - base];
	ret[index][] = str[base..length];
	
	return ret;
}

public size_t cstrlen(char* str)
{
    int i=0;
    
    while(str[i] != '\0')
    {
        i++;
    }
    
    return i;
}
