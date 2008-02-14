
module host;

// External dependencies (defined by host environment)
extern(C) void*  _d_malloc(size_t);
extern(C) size_t _d_palloc();
extern(C) size_t _d_allocsize(void*);
extern(C) void   _d_free(void*);
extern(C) void   _d_pfree(size_t);
extern(C) void   _d_putc(char);
extern(C) char   _d_getc();
extern(C) void   _d_abort();
extern(C) void   _d_error(char[] msg, char[] file, size_t line);

extern(C) void abort()
{
    _d_abort();
}
