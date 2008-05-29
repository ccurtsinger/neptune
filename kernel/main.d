module kernel.main;

import kernel.arch.native;

extern(C) void _main()
{
    startup();

    byte* b = cast(byte*)0xD00B8000;

    while(true)
    {
        b[0]++;
    }
}

extern(C) void abort()
{
    for(;;){}
}

extern (C) void _d_array_bounds(char[] file, uint line)
{

}

extern(C) void _d_assert_msg(char[] msg, char[] file, uint line)
{
    byte* b = cast(byte*)0xD00B8000;

    while(true)
    {
        b[2]++;
    }
}

extern(C) void _d_assert(char[] file, uint line)
{
    _d_assert_msg("assert failed", file, line);
}
