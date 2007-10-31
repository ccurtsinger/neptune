
import std.stdio;
import std.integer;

void onError(char[] msg, char[] file, ulong line)
{
	write("\n  ");
	write(msg);
	write(" (");
	write(file);
	write(", line ");
	write(line);
	write(")\n");
		
	for(;;){}
}

extern (C) void _d_assert(char[] file, uint line)
{
	onError("assert failed", file, line);
}

extern (C) static void _d_assert_msg(char[] msg, char[] file, uint line)
{
    onError(msg, file, line);
}

extern (C) void _d_array_bounds(char[] file, uint line)
{
    onError("array index out of bounds", file, line);
}

extern (C) void _d_switch_error(char[] file, uint line)
{
	onError("switch error", file, line);
}
