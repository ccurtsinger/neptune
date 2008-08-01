/**
 * A simple test server implementation
 *
 * Copyright: 2008 The Neptune Project
 */

extern(C) int _start()
{
    while(1 < 2)
    {
        asm
        {
            "int $128";
        }
    }
    
    return 0;
}

extern(C) void m_size()
{
    return 0;
}

extern(C) void m_alloc()
{

}

extern(C) void m_free()
{
    
}

extern(C) void p_alloc()
{
    
}

extern(C) void _d_error()
{
    
}

extern(C) void _d_abort()
{
    
}
