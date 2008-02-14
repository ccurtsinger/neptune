/**
 * Base structs for descriptor table entries.
 *
 * Authors: Charlie Curtsinger
 * Date: January 15th, 2008
 * Version: 0.2a
 */

module arch.x86_64.descriptor;

import std.bitarray;

/**
 * Descriptor type used in the entry
 */
enum DescriptorType
{
    LDT = 0x2,
    TSS = 0x9,
    TSS_BUSY = 0xB,
    CALL = 0xC,
    INTERRUPT = 0xE,
    TRAP = 0xF
}

/**
 * Descriptor table pointer
 * 
 * Used to load a descriptor table
 */
struct DTPtr
{
    align(1):
    ushort limit;
    void* address;
}

/**
 * Null descriptor used to start the GDT
 */
struct NullDescriptor
{
    ulong data;
    
    /**
     * False constructor
     *
     * Initializes the null descriptor to 0
     */
    public static NullDescriptor opCall()
    {
        NullDescriptor n;
        n.data = 0;
        
        return n;
    }
}

/**
 * Code segment descriptor for the GDT (or LDT in legacy mode)
 */
struct CodeDescriptor
{
    ulong data;
    
    /**
     * False constructor
     *
     * Initialize fixed bits for the descriptor
     */
    public static CodeDescriptor opCall()
    {
        CodeDescriptor c;
        BitArray bits = BitArray(&(c.data), 64);
        
        bits[43] = 1;
        bits[44] = 1;
        
        return c;
    }
	
	/**
	 * Get the base address for the code segment
	 */
    public uint base()
    {
        uint baseAddress;
        
        BitArray ret = BitArray(&baseAddress, 32);
        BitArray bits = BitArray(&data, 64);
        
        ret[0..24] = bits[16..40];
        ret[24..32] = bits[56..64];
        
        return baseAddress;
    }
    
    /**
     * Set the base address for the code segment
     */
    public void base(uint baseAddress)
    {
        BitArray base = BitArray(&baseAddress, 32);
        BitArray bits = BitArray(&data, 64);
        
        bits[16..40] = base[0..24];
        bits[56..64] = base[24..32];
    }
    
    /**
     * Get the limit size for the code segment
     */
    public uint limit()
    {
        uint limitSize;
        
        BitArray ret = BitArray(&limitSize, 32);
        BitArray bits = BitArray(&data, 64);
        
        ret[0..16] = bits[0..16];
        ret[16..20] = bits[48..52];
        
        return limitSize;
    }
    
    /**
     * Set the limit size for the code segment
     */
    public void limit(uint limitSize)
    {
        BitArray limit = BitArray(&limitSize, 32);
        BitArray bits = BitArray(&data, 64);
        
        bits[0..16] = limit[0..16];
        bits[48..52] = limit[16..20];
    }
    
    /**
     * Get the accessed bit
     */
    public bool accessed()
    {
        return BitArray(&data, 64)[40];
    }
    
    /**
     * Set the accessed bit
     */
    public void accessed(bool a)
    {
        BitArray(&data, 64)[40] = a;
    }
    
    /**
     * Get the readable bit
     */
    public bool readable()
    {
        return BitArray(&data, 64)[41];
    }
    
    /**
     * Set the readable bit
     */
    public void readable(bool r)
    {
        BitArray(&data, 64)[41] = r;
    }
    
    /**
     * Get the conforming bit
     */
    public bool conforming()
    {
        return BitArray(&data, 64)[42];
    }
    
    /**
     * Set the conforming bit
     */
    public void conforming(bool c)
    {
        BitArray(&data, 64)[42] = c;
    }
    
    /**
     * Get the privilege level for the descriptor
     */
    public ubyte privilege()
    {
        ubyte dpl;
        
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        dplbits[0..2] = bits[45..47];
        
        return dpl;
    }
    
    /**
     * Set the privilege level for the descriptor
     */
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
    
    /**
     * Get the present bit
     */
    public bool present()
    {
        return BitArray(&data, 64)[47];
    }
    
    /**
     * Set the present bit
     */
    public void present(bool p)
    {
        BitArray(&data, 64)[47] = p;
    }
    
    /**
     * Get the available bit
     */
    public bool available()
    {
        return BitArray(&data, 64)[52];
    }
    
    /**
     * Set the available bit
     */
    public void available(bool avl)
    {
        BitArray(&data, 64)[52] = avl;
    }
    
    /**
     * Get the long mode bit
     */
    public bool longmode()
    {
        return BitArray(&data, 64)[53];
    }
    
    /**
     * Set the long mode bit
     */
    public void longmode(bool l)
    {
        BitArray(&data, 64)[53] = l;
    }
    
    /**
     * Get the operand size bit
     */
    public bool operand()
    {
        return BitArray(&data, 64)[54];
    }
    
    /**
     * Set the operand size bit
     */
    public void operand(bool d)
    {
        BitArray(&data, 64)[54] = d;
    }
    
    /**
     * Get the granularity bit
     */
    public bool granularity()
    {
        return BitArray(&data, 64)[55];
    }
    
    /**
     * Set the granularity bit
     */
    public void granularity(bool g)
    {
        BitArray(&data, 64)[55] = g;
    }
}

/**
 * Data segment descriptor for the GDT
 */
struct DataDescriptor
{
    ulong data;
    
    /**
     * Initialize data segment bits
     */
    public static DataDescriptor opCall()
    {
        DataDescriptor d;
        
        BitArray bits = BitArray(&(d.data), 64);
        
        bits[43] = 0;
        bits[44] = 1;
        bits[53] = 0;
        
        return d;
    }

	/**
	 * Get the descriptor base address
	 */
    public uint base()
    {
        uint baseAddress;
        
        BitArray ret = BitArray(&baseAddress, 32);
        BitArray bits = BitArray(&data, 64);
        
        ret[0..24] = bits[16..40];
        ret[24..32] = bits[56..64];
        
        return baseAddress;
    }
    
    /**
     * Set the descriptor base address
     */
    public void base(uint baseAddress)
    {
        BitArray base = BitArray(&baseAddress, 32);
        BitArray bits = BitArray(&data, 64);
        
        bits[16..40] = base[0..24];
        bits[56..64] = base[24..32];
    }
    
    /**
     * Get the descriptor limit size
     */
    public uint limit()
    {
        uint limitSize;
        
        BitArray ret = BitArray(&limitSize, 32);
        BitArray bits = BitArray(&data, 64);
        
        ret[0..16] = bits[0..16];
        ret[16..20] = bits[48..52];
        
        return limitSize;
    }
    
    /**
     * Set the descriptor limit size
     */
    public void limit(uint limitSize)
    {
        BitArray limit = BitArray(&limitSize, 32);
        BitArray bits = BitArray(&data, 64);
        
        bits[0..16] = limit[0..16];
        bits[48..52] = limit[16..20];
    }
    
    /**
     * Get the descriptor accessed bit state
     */
    public bool accessed()
    {
        return BitArray(&data, 64)[40];
    }
    
    /**
     * Set the descriptor accessed bit
     */
    public void accessed(bool a)
    {
        BitArray(&data, 64)[40] = a;
    }
    
    /**
     * Get the descriptor writable bit state
     */
    public bool writable()
    {
        return BitArray(&data, 64)[41];
    }
    
    /**
     * Set the descriptor writable bit state
     */
    public void writable(bool w)
    {
        BitArray(&data, 64)[41] = w;
    }
    
    /**
     * Get the stack expansion direction bit
     */
    public bool expand()
    {
        return BitArray(&data, 64)[42];
    }
    
    /**
     * Set the stack expansion direction bit
     */
    public void expand(bool e)
    {
        BitArray(&data, 64)[42] = e;
    }
    
    /**
     * Get the descriptor privelege level
     */
    public ubyte privilege()
    {
        ubyte dpl;
        
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        dplbits[0..2] = bits[45..47];
        
        return dpl;
    }
    
    /**
     * Set the descriptor privelege level
     */
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
    
    /**
     * Get the present bit state
     */
    public bool present()
    {
        return BitArray(&data, 64)[47];
    }
    
    /**
     * Set the present bit
     */
    public void present(bool p)
    {
        BitArray(&data, 64)[47] = p;
    }
    
    /**
     * Get the available bit state
     */
    public bool available()
    {
        return BitArray(&data, 64)[52];
    }
    
    /**
     * Set the available bit state
     */
    public void available(bool avl)
    {
        BitArray(&data, 64)[52] = avl;
    }
    
    /**
     * Get the operand size bit
     */
    public bool operand()
    {
        return BitArray(&data, 64)[54];
    }
    
    /**
     * Set the operand size bit
     */
    public void operand(bool d)
    {
        BitArray(&data, 64)[54] = d;
    }
    
    /**
     * Get the granularity bit
     */
    public bool granularity()
    {
        return BitArray(&data, 64)[55];
    }
    
    /**
     * Set the granularity bit
     */
    public void granularity(bool g)
    {
        BitArray(&data, 64)[55] = g;
    }
}

/**
 * System descriptor for the GDT
 */
struct SystemDescriptor
{
    ulong[2] data;
    
    /**
     * Set the system descriptor type bits
     */
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
    
    /**
     * Get the descriptor base address
     */
    public ulong base()
    {
        ulong b;
        BitArray bits = BitArray(data.ptr, 128);
        BitArray ret = BitArray(&b, 64);
        
        ret[0..24] = bits[16..40];
        ret[24..64] = bits[56..96];
        
        return b;
    }
    
    /**
     * Set the descriptor base address
     */
    public void base(uint baseAddress)
    {
        BitArray bits = BitArray(data.ptr, 128);
        BitArray b = BitArray(&baseAddress, 64);
        
        bits[16..40] = b[0..24];
        bits[56..96] = b[24..64];
    }
    
    /**
     * Get the descriptor limit size
     */
    public ulong limit()
    {
        ulong l;
        BitArray bits = BitArray(data.ptr, 128);
        BitArray ret = BitArray(&l, 64);
        
        ret[0..16] = bits[0..16];
        ret[16..20] = bits[48..52];
        
        return l;
    }
    
    /**
     * Set the descriptor limit size
     */
    public void limit(uint limitSize)
    {
        BitArray bits = BitArray(data.ptr, 128);
        BitArray l = BitArray(&limitSize, 64);
        
        bits[0..16] = l[0..16];
        bits[48..52] = l[16..20];
    }
    
    /**
     * Get the system descriptor type
     */
    public ubyte type()
    {
        ubyte t;
        BitArray bits = BitArray(data.ptr, 128);
        BitArray ret = BitArray(&t, 8);
        
        ret[0..4] = bits[40..44];
        
        return t;
    }
    
    /**
     * Set the system descriptor type
     */
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
	
	/**
	 * Get the descriptor privelege level
	 */
    public ubyte privilege()
    {
        ubyte dpl;
        
        BitArray dplbits = BitArray(&dpl, 8);
        BitArray bits = BitArray(&data, 64);
        
        dplbits[0..2] = bits[45..47];
        
        return dpl;
    }
    
    /**
     * Set the descriptor privilege level
     */
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
    
    /**
     * Get the present bit
     */
    public bool present()
    {
        return BitArray(data.ptr, 128)[47];
    }
    
    /**
     * Set the present bit
     */
    public void present(bool p)
    {
        BitArray(data.ptr, 128)[47] = p;
    }
    
    /**
     * Get the descriptor granularity bit
     */
    public bool granularity()
    {
        return BitArray(data.ptr, 128)[55];
    }
    
    /**
     * Set the descriptor granularity bit
     */
    public void granularity(bool g)
    {
        BitArray(data.ptr, 128)[55] = g;
    }
}

/**
 * Gate descriptor for the IDT
 */
struct GateDescriptor
{
    ulong data1;
    ulong data2;
    
    /**
     * Set the gate descriptor bits
     */
    static GateDescriptor opCall()
    {
        GateDescriptor g;
        
        BitArray bits = BitArray(&(g.data1), 128);
        
        bits[35..40] = 0;
        bits[44] = 0;
        bits[96..128] = 0;
        
        return g;
    }
    
    /**
     * Get the target address
     */
    public ulong target()
    {
        ulong t;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&t, 64);
        
        ret[0..16] = bits[0..16];
        ret[16..64] = bits[48..96];
        
        return t;
    }
    
    /**
     * Set the target address
     */
    public void target(ulong targetOffset)
    {
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&targetOffset, 64);
        
        bits[0..16] = ret[0..16];
        bits[48..96] = ret[16..64];
    }
    
    /**
     * Get the descriptor type
     */
    public DescriptorType type()
    {
        DescriptorType t;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&t, 8);
        
        ret[0..4] = bits[40..44];
        
        return t;
    }
    
    /**
	 * Set the descriptor type
	 */
    public void type(DescriptorType t)
    {
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&t, 8);
        
        bits[40..44] = ret[0..4];
    }
    
    /**
     * Get the segment selector
     */
    public ushort selector()
    {
        ushort sel;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&sel, 16);
        
        ret[0..16] = bits[16..32];
        
        return sel;
    }
    
    /**
     * Set the segment selector
     */
    public void selector(ushort targetSelector)
    {
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&targetSelector, 16);
        
        bits[16..32] = ret[0..16];
    }
    
    /**
     * Get the stack IST index
     */
    public ubyte stack()
    {
        ubyte ist;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&ist, 8);
        
        ret[0..3] = bits[32..35];
        
        return ist;
    }
    
    /**
     * Set the stack IST index
     */
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
    
    /**
     * Get the descriptor privilege level
     */
    public ubyte privilege()
    {
        ubyte dpl;
        
        BitArray bits = BitArray(&data1, 128);
        BitArray ret = BitArray(&dpl, 8);
        
        ret[0..2] = bits[45..47];
        
        return dpl;
    }
    
    /**
     * Set the descriptor privelege level
     */
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
    
    /**
     * Get the present bit
     */
    public bool present()
    {
        return BitArray(&data1, 128)[47];
    }
    
    /**
     * Set the present bit
     */
    public void present(bool p)
    {
        BitArray(&data1, 128)[47] = p;
    }
}

