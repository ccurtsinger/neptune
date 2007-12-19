module kernel.arch.Descriptor;

import std.bitarray;

enum DescriptorType
{
    LDT = 0x2,
    TSS = 0x9,
    TSS_BUSY = 0xB,
    CALL = 0xC,
    INTERRUPT = 0xE,
    TRAP = 0xF
}

struct DTPtr
{
    align(1):
    ushort limit;
    void* address;
}

struct NullDescriptor
{
    ulong data;
    
    public static NullDescriptor opCall()
    {
        NullDescriptor n;
        n.data = 0;
        
        return n;
    }
}

struct CodeDescriptor
{
    ulong data;
    
    public static CodeDescriptor opCall()
    {
        CodeDescriptor c;
        BitArray bits = BitArray(&(c.data), 64);
        
        bits[43] = 1;
        bits[44] = 1;
        
        return c;
    }

    public uint base()
    {
        uint baseAddress;
        
        BitArray ret = BitArray(&baseAddress, 32);
        BitArray bits = BitArray(&data, 64);
        
        ret[0..24] = bits[16..40];
        ret[24..32] = bits[56..64];
        
        return baseAddress;
    }
    
    public void base(uint baseAddress)
    {
        BitArray base = BitArray(&baseAddress, 32);
        BitArray bits = BitArray(&data, 64);
        
        bits[16..40] = base[0..24];
        bits[56..64] = base[24..32];
    }
    
    public uint limit()
    {
        uint limitSize;
        
        BitArray ret = BitArray(&limitSize, 32);
        BitArray bits = BitArray(&data, 64);
        
        ret[0..16] = bits[0..16];
        ret[16..20] = bits[48..52];
        
        return limitSize;
    }
    
    public void limit(uint limitSize)
    {
        BitArray limit = BitArray(&limitSize, 32);
        BitArray bits = BitArray(&data, 64);
        
        bits[0..16] = limit[0..16];
        bits[48..52] = limit[16..20];
    }
    
    public bool accessed()
    {
        return BitArray(&data, 64)[40];
    }
    
    public void accessed(bool a)
    {
        BitArray(&data, 64)[40] = a;
    }
    
    public bool readable()
    {
        return BitArray(&data, 64)[41];
    }
    
    public void readable(bool r)
    {
        BitArray(&data, 64)[41] = r;
    }
    
    public bool conforming()
    {
        return BitArray(&data, 64)[42];
    }
    
    public void conforming(bool c)
    {
        BitArray(&data, 64)[42] = c;
    }
    
    public ubyte privilege()
    {
        ubyte dpl;
        
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        dplbits[0..2] = bits[45..47];
        
        return dpl;
    }
    
    public void privilege(ubyte dpl)
    in
    {
        assert(dpl < 4, "Invalid descriptor privilege level");
    }
    body
    {
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        bits[45..47] = dpl;
    }
    
    public bool present()
    {
        return BitArray(&data, 64)[47];
    }
    
    public void present(bool p)
    {
        BitArray(&data, 64)[47] = p;
    }
    
    public bool available()
    {
        return BitArray(&data, 64)[52];
    }
    
    public void available(bool avl)
    {
        BitArray(&data, 64)[52] = avl;
    }
    
    public bool longmode()
    {
        return BitArray(&data, 64)[53];
    }
    
    public void longmode(bool l)
    {
        BitArray(&data, 64)[53] = l;
    }
    
    public bool operand()
    {
        return BitArray(&data, 64)[54];
    }
    
    public void operand(bool d)
    {
        BitArray(&data, 64)[54] = d;
    }
    
    public bool granularity()
    {
        return BitArray(&data, 64)[55];
    }
    
    public void granularity(bool g)
    {
        BitArray(&data, 64)[55] = g;
    }
}

struct DataDescriptor
{
    ulong data;
    
    public static DataDescriptor opCall()
    {
        DataDescriptor d;
        
        BitArray bits = BitArray(&(d.data), 64);
        
        bits[43] = 0;
        bits[44] = 1;
        bits[53] = 0;
        
        return d;
    }

    public uint base()
    {
        uint baseAddress;
        
        BitArray ret = BitArray(&baseAddress, 32);
        BitArray bits = BitArray(&data, 64);
        
        ret[0..24] = bits[16..40];
        ret[24..32] = bits[56..64];
        
        return baseAddress;
    }
    
    public void base(uint baseAddress)
    {
        BitArray base = BitArray(&baseAddress, 32);
        BitArray bits = BitArray(&data, 64);
        
        bits[16..40] = base[0..24];
        bits[56..64] = base[24..32];
    }
    
    public uint limit()
    {
        uint limitSize;
        
        BitArray ret = BitArray(&limitSize, 32);
        BitArray bits = BitArray(&data, 64);
        
        ret[0..16] = bits[0..16];
        ret[16..20] = bits[48..52];
        
        return limitSize;
    }
    
    public void limit(uint limitSize)
    {
        BitArray limit = BitArray(&limitSize, 32);
        BitArray bits = BitArray(&data, 64);
        
        bits[0..16] = limit[0..16];
        bits[48..52] = limit[16..20];
    }
    
    public bool accessed()
    {
        return BitArray(&data, 64)[40];
    }
    
    public void accessed(bool a)
    {
        BitArray(&data, 64)[40] = a;
    }
    
    public bool writable()
    {
        return BitArray(&data, 64)[41];
    }
    
    public void writable(bool w)
    {
        BitArray(&data, 64)[41] = w;
    }
    
    public bool expand()
    {
        return BitArray(&data, 64)[42];
    }
    
    public void expand(bool e)
    {
        BitArray(&data, 64)[42] = e;
    }
    
    public ubyte privilege()
    {
        ubyte dpl;
        
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        dplbits[0..2] = bits[45..47];
        
        return dpl;
    }
    
    public void privilege(ubyte dpl)
    in
    {
        assert(dpl < 4, "Invalid descriptor privilege level");
    }
    body
    {
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        bits[45..47] = dpl;
    }
    
    public bool present()
    {
        return BitArray(&data, 64)[47];
    }
    
    public void present(bool p)
    {
        BitArray(&data, 64)[47] = p;
    }
    
    public bool available()
    {
        return BitArray(&data, 64)[52];
    }
    
    public void available(bool avl)
    {
        BitArray(&data, 64)[52] = avl;
    }
    
    public bool operand()
    {
        return BitArray(&data, 64)[54];
    }
    
    public void operand(bool d)
    {
        BitArray(&data, 64)[54] = d;
    }
    
    public bool granularity()
    {
        return BitArray(&data, 64)[55];
    }
    
    public void granularity(bool g)
    {
        BitArray(&data, 64)[55] = g;
    }
}

struct SystemDescriptor
{
    ulong[2] data;
    
    public static SystemDescriptor opCall()
    {
        SystemDescriptor s;
        
        BitArray bits = BitArray((s.data.ptr), 128);
        
        bits[44] = 0;
        bits[53] = 0;
        bits[54] = 0;
        bits[96..128] = 0;
        
        return s;
    }
    
    public vaddr_t base()
    {
        vaddr_t b;
        BitArray bits = BitArray(data.ptr, 128);
        BitArray ret = BitArray(&b, 64);
        
        ret[0..24] = bits[16..40];
        ret[24..64] = bits[56..96];
        
        return b;
    }
    
    public void base(uint baseAddress)
    {
        BitArray bits = BitArray(data.ptr, 128);
        BitArray b = BitArray(&baseAddress, 64);
        
        bits[16..40] = b[0..24];
        bits[56..96] = b[24..64];
    }
    
    public size_t limit()
    {
        size_t l;
        BitArray bits = BitArray(data.ptr, 128);
        BitArray ret = BitArray(&l, 64);
        
        ret[0..16] = bits[0..16];
        ret[16..20] = bits[48..52];
        
        return l;
    }
    
    public void limit(uint limitSize)
    {
        BitArray bits = BitArray(data.ptr, 128);
        BitArray l = BitArray(&limitSize, 64);
        
        bits[0..16] = l[0..16];
        bits[48..52] = l[16..20];
    }
    
    public ubyte type()
    {
        ubyte t;
        BitArray bits = BitArray(data.ptr, 128);
        BitArray ret = BitArray(&t, 8);
        
        ret[0..4] = bits[40..44];
        
        return t;
    }
    
    public void type(ubyte t)
    in
    {
        if((t != DescriptorType.LDT &&
            t != DescriptorType.TSS &&
            t != DescriptorType.TSS_BUSY &&
            t != DescriptorType.CALL) || t > 0xF)
        {
            assert(false, "Invalid System Descriptor type");
        }
    }
    body
    {
        BitArray bits = BitArray(data.ptr, 128);
        BitArray tp = BitArray(&t, 8);
        
        bits[40..44] = tp[0..4];
    }

    public ubyte privilege()
    {
        ubyte dpl;
        
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        dplbits[0..2] = bits[45..47];
        
        return dpl;
    }
    
    public void privilege(ubyte dpl)
    in
    {
        assert(dpl < 4, "Invalid descriptor privilege level");
    }
    body
    {
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        bits[45..47] = dpl;
    }
    
    public bool present()
    {
        return BitArray(data.ptr, 128)[47];
    }
    
    public void present(bool p)
    {
        BitArray(data.ptr, 128)[47] = p;
    }
    
    public bool granularity()
    {
        return BitArray(data.ptr, 128)[55];
    }
    
    public void granularity(bool g)
    {
        BitArray(data.ptr, 128)[55] = g;
    }
}

struct GateDescriptor
{
    ulong data1;
    ulong data2;
    
    static GateDescriptor opCall()
    {
        GateDescriptor g;
        
        BitArray bits = BitArray(&(g.data1), 128);
        
        bits[35..40] = 0;
        bits[44] = 0;
        bits[96..128] = 0;
        
        return g;
    }
    
    public ulong target()
    {
        ulong t;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&t, 64);
        
        ret[0..16] = bits[0..16];
        ret[16..64] = bits[48..96];
        
        return t;
    }
    
    public void target(ulong targetOffset)
    {
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&targetOffset, 64);
        
        bits[0..16] = ret[0..16];
        bits[48..96] = ret[16..64];
    }
    
    public DescriptorType type()
    {
        DescriptorType t;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&t, 8);
        
        ret[0..4] = bits[40..44];
        
        return t;
    }
    
    public void type(DescriptorType t)
    {
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&t, 8);
        
        bits[40..44] = ret[0..4];
    }
    
    public ushort selector()
    {
        ushort sel;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&sel, 16);
        
        ret[0..16] = bits[16..32];
        
        return sel;
    }
    
    public void selector(ushort targetSelector)
    {
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&targetSelector, 16);
        
        bits[16..32] = ret[0..16];
    }
    
    public ubyte stack()
    {
        ubyte ist;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&ist, 8);
        
        ret[0..3] = bits[32..35];
        
        return ist;
    }
    
    public void stack(ubyte ist)
    in
    {
        assert(ist < 8, "Invalid IST index");
    }
    body
    {
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&ist, 8);
        
        bits[32..35] = ret[0..3];
    }
    
    public ubyte privilege()
    {
        ubyte dpl;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&dpl, 8);
        
        ret[0..2] = bits[45..47];
        
        return dpl;
    }
    
    public void privilege(ubyte dpl)
    in
    {
        assert(dpl < 4, "Invalid descriptor privilege level");
    }
    body
    {
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&dpl, 8);
        
        bits[45..47] = ret[0..2];
    }
    
    public bool present()
    {
        return BitArray(&data1, 128)[47];
    }
    
    public void present(bool p)
    {
        BitArray(&data1, 128)[47] = p;
    }
}

