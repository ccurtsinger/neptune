/**
 * Extern(c)s for functions expected to be provided by the host environment
 *
 * Copyright: 2008 The Neptune Project
 */

module host;

// External dependencies (defined by host environment)
extern(C) void*  m_alloc(size_t);
extern(C) size_t p_alloc();
extern(C) size_t m_size(void*);
extern(C) void   m_free(void*);
extern(C) void   p_free(size_t);

extern(C) char   _d_getc();
extern(C) void   _d_abort();
extern(C) void   _d_error(char[] msg, char[] file, size_t line);

extern(C) void abort()
{
    _d_abort();
}

extern(C) void* ptov(size_t);
extern(C) size_t vtop(void*);
