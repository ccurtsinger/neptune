/**
 * Multiboot header structures and utilities
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.spec.multiboot;

import kernel.arch.native;

import std.bitarray;
import std.string;

/* The Multiboot header. */
struct MultibootHeader
{
	uint magic;
	uint flags;
	uint checksum;
	uint header_addr;
	uint load_addr;
	uint load_end_addr;
	uint bss_end_addr;
	uint entry_addr;
}

/* The Multiboot information. */
struct MultibootInfo
{
    /// Flags that indicate which information is usable
    union
    {
        private uint flags;
        private BitArray flag_bits;
    }
	
	/// Upper and lower memory sizes
	private uint mem_lower;
	private uint mem_upper;
	
	/// Boot device information
	private uint boot_device;
	
	/// Pointer to the command used to launch the executable
	private uint cmdline;
	
	/// Module information
	private uint mods_count;
	private uint mods_addr;
	
	/// Information about the executable
	union
	{
        private ElfHeaderTable elf_sec;
        private AOutSymbolTable aout_sym;
	}
    
    /// Information about memory regions
	private uint mmap_length;
	private size_t mmap_addr;
	
	/// Information about system drives
	private uint drives_length;
	private uint drives_addr;
	
	/// Pointer to the boot loader name
	private uint boot_loader_name;
	
	/// Pointer to the APM table
	private uint apm_table;
	
	/// VBE information and info table pointers
	private uint vbe_control_info;
	private uint vbe_mode_info;
	private uint vbe_mode;
	private uint vbe_interface_seg;
	private uint vbe_interface_off;
	private uint vbe_interface_len;
	
	public ulong getLowerMemSize()
	{
	    if(flag_bits[0])
	        return mem_lower * 1024;
	    
	    return 0;
	}
	
	public ulong getUpperMemSize()
	{
	    if(flag_bits[0])
	        return mem_upper * 1024;
	    
	    return 0;
	}
	
	public char[] getCommand()
	{
	    if(flag_bits[2])
	    {
	        return ctodstr(cast(char*)ptov(cmdline));
	    }
        
        return "";
	}
	
	public MultibootModule[] getModules()
	{
	    MultibootModule* m = cast(MultibootModule*)ptov(mods_addr);
        return m[0..mods_count];
	}
	
	public MemoryMap getMemoryMap()
	{
	    return MemoryMap(cast(MemoryMapEntry*)ptov(mmap_addr), mmap_length);
	}
}

/* The symbol table for a.out. */
struct AOutSymbolTable
{
	uint tabsize;
	uint strsize;
	uint addr;
	uint reserved;
}

/* The section header table for ELF. */
struct ElfHeaderTable
{
	uint num;
	uint size;
	uint addr;
	uint shndx;
}

/* The module structure. */
struct MultibootModule
{
	private byte* mod_start;
	private byte* mod_end;
	private char* string;
	private uint reserved;
	
	char[] getString()
	{
	    size_t len = cstrlen(string);
	    
	    return string[0..len];
	}
	
	byte[] getData()
	{
	    size_t size = mod_end - mod_start;
	    
	    return mod_start[0..size];
	}
	
	size_t getBase()
	{
	    return cast(size_t)mod_start;
	}
	
	size_t getSize()
	{
	    return cast(size_t)(mod_end - mod_start);
	}
}

struct MemoryMap
{
    private MemoryMapEntry* first;
    private MemoryMapEntry* current;
    private size_t size;
    
    public static MemoryMap opCall(MemoryMapEntry* first, size_t size)
    {
        MemoryMap m;
        m.first = first;
        m.size = size;
        return m;
    }
    
    private bool next()
    {
        current = cast(MemoryMapEntry*)(cast(size_t)current + current.entry_size + uint.sizeof);
        
        if(cast(size_t)current < cast(size_t)first + size)
            return true;
        
        return false;
    }
    
    int opApply(int delegate(ref MemoryMapEntry* p) dg)
    {
        int result = 0;
        current = first;
        
        do
        {
            result = dg(current);
            
            if(result)
                break;
                
        } while(next());
        
        return result;
    }
    
    MemoryMapEntry* opIndex(size_t index)
    {
        size_t i = 0;
        
        current = first;
        
        do
        {
            if(i == index)
                return current;
                
            i++;
            
        } while(next());
        
        assert(false, "memory map index out of bounds");
    }
    
    size_t length()
    {
        size_t l = 0;
        
        current = first;
        
        do
        {
            l++;
        } while(next());
        
        return l;
    }
}

struct MemoryMapEntry
{
	private uint entry_size;
	private uint baseLow;
	private uint baseHigh;
	private uint lengthLow;
	private uint lengthHigh;
	private uint entry_type;
	
	public ulong base()
	{
	    //return (cast(ulong)baseHigh)*0xFFFFFFFF + baseLow;
	    return baseLow;
	}
	
	public ulong size()
	{
	    //return (cast(ulong)lengthHigh)*0xFFFFFFFF + lengthLow;
	    return lengthLow;
	}
	
	public uint type()
	{
	    return entry_type;
	}
}
