/**
 * Structures for creating descriptor table entires
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module util.arch.descriptor;

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
    ulong address;
    
    public static DTPtr opCall(ushort limit, ulong address)
    {
        DTPtr t;
        t.limit = limit;
        t.address = address;
        return t;
    }
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

struct Descriptor
{
    union
    {
        ulong data;
        BitArray bits;
    }
    
    public static Descriptor opCall(bool code)
    {
        Descriptor d;
        
        if(code)
        {
            d.bits[43] = 1;
            d.bits[44] = 1;
        }
        else
        {
            d.bits[43] = 0;
	        d.bits[44] = 1;
            d.bits[53] = 0;
        }
        
        return d;
    }
    
    public bool code()
    {
        return bits[43] && bits[44];
    }
	
	/**
	 * Get the base address for the code segment
	 */
    public uint base()
    {
        return bits[16..40] | (bits[56..64] << 24);
    }
    
    /**
     * Set the base address for the code segment
     */
    public void base(uint baseAddress)
    {
        auto base = BitArray(&baseAddress);
        
        bits[16..40] = (*base)[0..24];
        bits[56..64] = (*base)[24..32];
    }
    
    /**
     * Get the limit size for the code segment
     */
    public uint limit()
    {
        return bits[0..16] | (bits[48..52] << 16);
    }
    
    /**
     * Set the limit size for the code segment
     */
    public void limit(uint limitSize)
    {
        auto limit = BitArray(&limitSize);
        
        bits[0..16] = (*limit)[0..16];
        bits[48..52] = (*limit)[16..20];
    }
    
    /**
     * Get the accessed bit
     */
    public bool accessed()
    {
        return bits[40];
    }
    
    /**
     * Set the accessed bit
     */
    public void accessed(bool a)
    {
        bits[40] = a;
    }
    
    /**
     * Get the readable bit
     */
    public bool readable()
    {
        assert(code, "readable() is only available for code descriptors");
        return bits[41];
    }
    
    /**
     * Set the readable bit
     */
    public void readable(bool r)
    {
        assert(code, "readable() is only available for code descriptors");
        bits[41] = r;
    }
    
    /**
     * Get the conforming bit
     */
    public bool conforming()
    {
        assert(code, "conforming() is only available for code descriptors");
        return bits[42];
    }
    
    /**
     * Set the conforming bit
     */
    public void conforming(bool c)
    {
        assert(code, "conforming() is only available for code descriptors");
        bits[42] = c;
    }
    
    /**
     * Get the descriptor writable bit state
     */
    public bool writable()
    {
        assert(!code, "writable() is only available for data descriptors");
        return bits[41];
    }
    
    /**
     * Set the descriptor writable bit state
     */
    public void writable(bool w)
    {
        assert(!code, "writable() is only available for data descriptors");
        bits[41] = w;
    }
    
    /**
     * Get the stack expansion direction bit
     */
    public bool expand()
    {
        assert(!code, "expand() is only available for data descriptors");
        return bits[42];
    }
    
    /**
     * Set the stack expansion direction bit
     */
    public void expand(bool e)
    {
        assert(!code, "expand() is only available for data descriptors");
        bits[42] = e;
    }
    
    /**
     * Get the privilege level for the descriptor
     */
    public ubyte privilege()
    {
        return cast(ubyte)bits[45..47];
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
        bits[45..47] = dpl;
    }
    
    /**
     * Get the present bit
     */
    public bool present()
    {
        return bits[47];
    }
    
    /**
     * Set the present bit
     */
    public void present(bool p)
    {
        bits[47] = p;
    }
    
    /**
     * Get the long mode bit
     */
    public bool longmode()
    {
        assert(code, "longmode() is only available for code descriptors");
        return bits[53];
    }
    
    /**
     * Set the long mode bit
     */
    public void longmode(bool l)
    {
        assert(code, "longmode() is only available for code descriptors");
        bits[53] = l;
    }
    
    /**
     * Get the operand size bit
     */
    public bool operand()
    {
        return bits[54];
    }
    
    /**
     * Set the operand size bit
     */
    public void operand(bool d)
    {
        bits[54] = d;
    }
    
    /**
     * Get the granularity bit
     */
    public bool granularity()
    {
        return bits[55];
    }
    
    /**
     * Set the granularity bit
     */
    public void granularity(bool g)
    {
        bits[55] = g;
    }
}

/**
 * System descriptor for the GDT
 */
struct SystemDescriptor
{
    union
    {
        ulong[2] data;
        BitArray bits;
    }
    
    /**
     * Set the system descriptor type bits
     */
    public static SystemDescriptor opCall()
    {
        SystemDescriptor s;
        
        s.bits[44] = 0;
        s.bits[53] = 0;
        s.bits[54] = 0;
        s.bits[96..128] = 0;
        
        return s;
    }
    
    /**
     * Get the descriptor base address
     */
    public ulong base()
    {
        return bits[16..40] | (bits[56..96] << 24);
    }
    
    /**
     * Set the descriptor base address
     */
    public void base(ulong baseAddress)
    {
        auto base = BitArray(&baseAddress);
        
        bits[16..40] = (*base)[0..24];
        bits[56..96] = (*base)[24..64];
    }
    
    /**
     * Get the descriptor limit size
     */
    public ulong limit()
    {
        return bits[0..16] | (bits[48..52] << 15);
    }
    
    /**
     * Set the descriptor limit size
     */
    public void limit(uint limitSize)
    {
        auto limit = BitArray(&limitSize);
        
        bits[0..16] = (*limit)[0..16];
        bits[48..52] = (*limit)[16..20];
    }
    
    /**
     * Get the system descriptor type
     */
    public ubyte type()
    {
        return bits[40..44];
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
        bits[40..44] = t;
    }
	
	/**
	 * Get the descriptor privelege level
	 */
    public ubyte privilege()
    {
        return bits[45..47];
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
        bits[45..47] = dpl;
    }
    
    /**
     * Get the present bit
     */
    public bool present()
    {
        return bits[47];
    }
    
    /**
     * Set the present bit
     */
    public void present(bool p)
    {
        bits[47] = p;
    }
    
    /**
     * Get the descriptor granularity bit
     */
    public bool granularity()
    {
        return bits[55];
    }
    
    /**
     * Set the descriptor granularity bit
     */
    public void granularity(bool g)
    {
        bits[55] = g;
    }
}

/**
 * Gate descriptor for the IDT
 */
struct GateDescriptor
{
    union
    {
        ulong[2] data;
        BitArray bits;
    }
    
    /**
     * Set the gate descriptor bits
     */
    static GateDescriptor opCall()
    {
        GateDescriptor g;
        
        g.bits[35..40] = 0;
        g.bits[44] = 0;
        g.bits[96..128] = 0;
        
        return g;
    }
    
    /**
     * Get the target address
     */
    public ulong target()
    {
        return bits[0..16] | (bits[48..96] << 16);
    }
    
    /**
     * Set the target address
     */
    public void target(ulong targetOffset)
    {
        auto target = BitArray(&targetOffset);
        
        bits[0..16] = (*target)[0..16];
        bits[48..96] = (*target)[16..64];
    }
    
    /**
     * Get the descriptor type
     */
    public DescriptorType type()
    {
        return cast(DescriptorType)bits[40..44];
    }
    
    /**
	 * Set the descriptor type
	 */
    public void type(DescriptorType t)
    {
        bits[40..44] = t;
    }
    
    /**
     * Get the segment selector
     */
    public ushort selector()
    {
        return bits[16..32];
    }
    
    /**
     * Set the segment selector
     */
    public void selector(ushort targetSelector)
    {
        bits[16..32] = targetSelector;
    }
    
    /**
     * Get the stack IST index
     */
    public ubyte stack()
    {
        return bits[32..35];
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
        bits[32..35] = ist;
    }
    
    /**
     * Get the descriptor privilege level
     */
    public ubyte privilege()
    {
        return bits[45..47];
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
        bits[45..47] = dpl;
    }
    
    /**
     * Get the present bit
     */
    public bool present()
    {
        return bits[47];
    }
    
    /**
     * Set the present bit
     */
    public void present(bool p)
    {
        bits[47] = p;
    }
}
