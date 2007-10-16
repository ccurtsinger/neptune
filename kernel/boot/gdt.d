module boot.gdt;

ulong[256] gdt;
GDTPtr gdtp;
TSS tss;
ushort tssSel;

void gdt_install()
{
    gdt[0] = 0;                     // null descriptor
    gdt[1] = 0x00AF9A000000FFFF;    // kernel code descriptor
    gdt[2] = 0x00AF92000000FFFF;    // kerel data descriptor
    gdt[3] = 0x00AFFA000000FFFF;    // user code descriptor
    gdt[4] = 0x00AFF2000000FFFF;    // user data descriptor

    //TSS Descriptor

    // Set limit
    gdt[5] = 0x67;

    // Set base bytes 1, 2, and 3
    gdt[5] |= (cast(ulong)&tss << 16) & 0xFFFFFF0000L;

    // Set base byte 4
    gdt[5] |= (cast(ulong)&tss << 32) & 0xFF00000000000000L;

    // Set P, DPL, and type
    gdt[5] |= 0x0000890000000000L;

    gdt[6] = 0;
    gdt[6] = (cast(ulong)&tss >> 32) & 0xFFFFFFFFL;

    gdtp.limit = 7 * ulong.sizeof - 1;
    gdtp.address = cast(ulong)(&(gdt[0]));

    // Set up TSS
    tss.res1 = 0;
    tss.res2 = 0;
    tss.res3 = 0;
    tss.res4 = 0;
    tss.iomap = 0;

    tss.rsp0 = 0xFFFF810000000000;
    tss.rsp1 = 0xFFFF810000000000;
    tss.rsp2 = 0xFFFF810000000000;

    tss.ist[0] = 0x7FFFFFF8;
    tss.ist[1] = 0x7FFFFFF8;
    tss.ist[2] = 0x7FFFFFF8;
    tss.ist[3] = 0x7FFFFFF8;
    tss.ist[4] = 0x7FFFFFF8;
    tss.ist[5] = 0x7FFFFFF8;
    tss.ist[6] = 0x7FFFFFF8;

    tssSel = 0x28;

    asm
    {
        "lgdt (%[gdtp])" : : [gdtp] "b" &gdtp;
        "ltr %[tssSel]" : : [tssSel] "b" tssSel;
    }
}

struct GDTPtr
{
    align(1):
    ushort limit;
    ulong address;
}

struct TSS
{
    align(1):

    uint res1;

    ulong rsp0;
    ulong rsp1;
    ulong rsp2;

    ulong res2;

    ulong[7] ist;

    ulong res3;
    ushort res4;

    ushort iomap;
}
