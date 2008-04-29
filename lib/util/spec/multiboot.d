/**
 * Multiboot header structures and utilities
 *
 * Developed from the GNU-licenesed Multiboot specification
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module spec.multiboot;

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
	private char* cmdline;
	
	/// Module information
	private uint mods_count;
	private MultibootModule* mods_addr;
	
	/// Information about the executable
	union
	{
        private ElfHeaderTable elf_sec;
        private AOutSymbolTable aout_sym;
	}
    
    /// Information about memory regions
	private uint mmap_length;
	private MemoryMap* mmap_addr;
	
	/// Information about system drives
	private uint drives_length;
	private uint drives_addr;
	
	/// Pointer to the boot loader name
	private char* boot_loader_name;
	
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
	    size_t len = cstrlen(cmdline);
	    
	    if(flag_bits[2])
            return cmdline[0..len];
        
        return "";
	}
	
	public MultibootModule[] getModules()
	{
        return mods_addr[0..mods_count];
	}
	
	public MemoryMap* getMemoryMap()
	{
	    return mmap_addr;
	}
	
	public size_t getMemoryMapSize()
	{
	    return mmap_length;
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

/* The memory map. Be careful that the offset 0 is base_addr_low
but no size. */
struct MemoryMap
{
	private uint size;
	private uint baseLow;
	private uint baseHigh;
	private uint lengthLow;
	private uint lengthHigh;
	private uint type;
	
	public ulong getBase()
	{
	    //return (cast(ulong)baseHigh)*0xFFFFFFFF + baseLow;
	    return baseLow;
	}
	
	public ulong getLength()
	{
	    //return (cast(ulong)lengthHigh)*0xFFFFFFFF + lengthLow;
	    return lengthLow;
	}
	
	public uint getType()
	{
	    return type;
	}
	
	public MemoryMap* next()
	{
	    return cast(MemoryMap*)(cast(uint)&size + size + uint.sizeof);
	}
}
