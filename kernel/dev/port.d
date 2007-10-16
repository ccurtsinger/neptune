module dev.port;

ubyte inp(ushort p)
{
    ubyte ret = void;
    asm {"inb %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

ushort inpw(ushort p)
{
    ushort ret = void;
    asm {"inw %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

uint inpl(ushort p)
{
    uint ret = void;
    asm {"inl %[port], %[result]" : [result] "=a" ret : [port] "Nd" p; }
    return ret;
}

void outp(ushort p, ubyte d)
{
    asm {"outb %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}

void outpw(ushort p, ushort d)
{
    asm {"outw %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}

void outpl(ushort p, uint d)
{
    asm {"outl %[data], %[port]" : : [port] "Nd" p, [data] "a" d; }
}
