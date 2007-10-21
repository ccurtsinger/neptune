module std.port;

/**
 * Reads I/O port at port_address.
 */
ubyte inp(ushort p)
{
    ubyte ret = void;
    asm {"inb %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

/**
 * ditto
 */
ushort inpw(ushort p)
{
    ushort ret = void;
    asm {"inw %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

/**
 * ditto
 */
uint inpl(ushort p)
{
    uint ret = void;
    asm {"inl %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

/**
 * Writes and returns value to I/O port at port_address.
 */
void outp(ushort p, ubyte d)
{
    asm {"outb %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}

/**
 * ditto
 */
void outpw(ushort p, ushort d)
{
    asm {"outw %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}

/**
 * ditto
 */
void outpl(ushort p, uint d)
{
    asm {"outl %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}
