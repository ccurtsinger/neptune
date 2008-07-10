/**
 * Multiboot header structures and utilities
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.spec.multiboot;

import kernel.arch.constants;
import kernel.mem.physical;
import kernel.mem.range;
import kernel.spec.elf;

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
    private uint elf_sec_num;
	private uint elf_sec_size;
	private uint elf_sec_addr;
	private uint elf_sec_shndx;
    
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
	        return ctodstr(cast(char*)cmdline);
	    }
        
        return "";
	}
	
	public MultibootModule[] getModules()
	{
	    MultibootModule* m = cast(MultibootModule*)mods_addr;
        return m[0..mods_count];
	}
	
	public MemoryMap getMemoryMap()
	{
	    return MemoryMap(cast(MemoryMapEntry*)mmap_addr, mmap_length);
	}
	
	public ElfSectionHeader[] getElfSectionHeaders()
	{
	    if(flag_bits[5])
            return (cast(ElfSectionHeader*)elf_sec_addr)[0..elf_sec_num];
        else
            return null;
	}
	
	public MemoryRange getKernelMemoryRange()
	{
	    // Track the highest section upper-boundary
        size_t kernel_top = 0;
        
        foreach(i, s; getElfSectionHeaders())
        {
            if(s.getOffset() + s.getSize() > kernel_top)
                kernel_top = s.getOffset() + s.getSize();
        }

        // Compute the top of the kernel binary
        kernel_top += KERNEL_PHYSICAL_ENTRY;

        return MemoryRange(KERNEL_PHYSICAL_ENTRY, kernel_top);
	}
	
	public void initMemory()
	{
	    // Free memory from the multiboot memory map
        foreach(mem; getMemoryMap())
        {
            // If memory region is available
            if(mem.type == 1)
            {
                // Determine the offset into a page frame of the base
                size_t offset = mem.base % FRAME_SIZE;
                
                // If the boundary isn't page-aligned, bump up to the next page
                if(offset != 0)
                    offset = FRAME_SIZE - offset;
                
                // Loop over all complete pages in the set
                for(size_t i=offset; i+FRAME_SIZE <= mem.size; i+=FRAME_SIZE)
                {
                    p_free(mem.base + i);
                }
            }
        }
        
        MemoryRange kernel = getKernelMemoryRange().aligned(FRAME_SIZE);
        
        // Mark all memory used by the kernel binary as occupied
        for(size_t i=kernel.base; i<kernel.top; i+=FRAME_SIZE)
        {
            p_set(i);
        }
        
        // Reserve memory for the multiboot module headers
        MultibootModule[] modules = getModules();
        
        MemoryRange module_mem = MemoryRange(cast(size_t)modules.ptr, modules.length*MultibootModule.sizeof).aligned(FRAME_SIZE);
        
        for(size_t i=module_mem.base; i<module_mem.top; i+=FRAME_SIZE)
        {
            p_set(i);
        }
        
        foreach(m; modules)
        {
            m.initMemory();
        }
	}
}

/* The module structure. */
struct MultibootModule
{
	private byte* mod_start;
	private byte* mod_end;
	private char* mod_string;
	private uint reserved;
	
	public char[] string()
	{
	    return ctodstr(mod_string);
	}
	
	public byte[] data()
	{
	    size_t size = mod_end - mod_start;
	    
	    return mod_start[0..size];
	}
	
	public size_t base()
	{
	    return cast(size_t)mod_start;
	}
	
	public size_t size()
	{
	    return cast(size_t)(mod_end - mod_start);
	}
	
	public MemoryRange range()
	{
	    return MemoryRange(base, base+size);
	}
	
	public void initMemory()
	{
	    p_set(cast(size_t)mod_string);
	    
	    MemoryRange data_mem = range.aligned(FRAME_SIZE);
	    
	    for(size_t i=data_mem.base; i<data_mem.top; i+=FRAME_SIZE)
	    {
	        p_set(i);
	    }
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
