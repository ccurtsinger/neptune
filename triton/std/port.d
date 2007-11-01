/**
 * CPU Port I/O functions
 *
 * Authors: Charlie Curtsinger
 * Date: October 31st, 2007
 * Version: 0.1b
 */

module std.port;

/**
 * Read a ubyte from port p
 *
 * Params:
 *  p = port to read from
 *
 * Returns: ubyte read
 */
ubyte inp(ushort p)
{
    ubyte ret = void;
    asm {"inb %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

/**
 * Read a ushort from port p
 *
 * Params:
 *  p = port to read from
 *
 * Returns: ushort read
 */
ushort inpw(ushort p)
{
    ushort ret = void;
    asm {"inw %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

/**
 * Read a uint from port p
 *
 * Params:
 *  p = port to read from
 *
 * Returns: uint read
 */
uint inpl(ushort p)
{
    uint ret = void;
    asm {"inl %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

/**
 * Write a ubyte to port p
 *
 * Params:
 *  p = port to write to
 *  d = data to write
 */
void outp(ushort p, ubyte d)
{
    asm {"outb %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}

/**
 * Write a ushort to port p
 *
 * Params:
 *  p = port to write to
 *  d = data to write
 */
void outpw(ushort p, ushort d)
{
    asm {"outw %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}

/**
 * Write a uint to port p
 *
 * Params:
 *  p = port to write to
 *  d = data to write
 */
void outpl(ushort p, uint d)
{
    asm {"outl %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}
