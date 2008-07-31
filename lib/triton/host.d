/**
 * Extern(c)s for functions expected to be provided by the host environment
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
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
