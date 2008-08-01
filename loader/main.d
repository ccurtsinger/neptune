/**
 * 32 bit Loader
 *
 * Copyright: 2008 The Neptune Project
 */

import util.arch.arch;
import util.arch.cpu;
import util.arch.gdt;
import util.arch.descriptor;
import util.arch.paging;

import util.spec.multiboot;
import util.spec.elf64;

import std.integer;
import std.stdio;
import std.string;
import std.mem;

import loader.host;

extern(C) LoaderData _data;

MemoryRegion[20] _mem;
MemoryRegion[20] _used_mem;

LoaderModule[20] _modules;

CPU cpu;

ulong[256] gdt_data;

struct LoaderData
{
    ulong L4;
    
    ulong numMemoryRegions;
    ulong memoryRegions;
    
    ulong numUsedRegions;
    ulong usedRegions;
    
    ulong elfHeader;
    
    ulong numModules;
    ulong modules;
}

struct LoaderModule
{
    ulong name;
    ulong base;
    ulong size;
}

struct MemoryRegion
{
    ulong base;
    ulong size;
    ulong type;
}

extern(C) ulong _setup(MultibootInfo* boot, uint magic)
{
    Elf64Header* elf;
    
    _data.numMemoryRegions = 0;
    _data.memoryRegions = cast(ulong)(&_mem) + LINEAR_MEM_BASE;
    
    _data.numUsedRegions = 0;
    _data.usedRegions = cast(ulong)(&_used_mem) + LINEAR_MEM_BASE;
    
    _data.numModules = 0;
    _data.modules = cast(ulong)&_modules + LINEAR_MEM_BASE;
    
    readMemInfo(boot);

    stdout = new Screen();

    clear();
    writeln("Executing 32 bit loader...");
    
    nextPage = 0x800000;
        
    ulong used_base = nextPage;

    writefln("Boot Command: %s", boot.getCommand());

    auto modules = boot.getModules();

    writefln("Modules Loaded: %u", modules.length);
    
    foreach(mod; modules)
    {
        writefln("  %s", mod.getString());
        
        addUsedRegion(mod.getBase(), mod.getSize());

        if(mod.getString() == "/boot/kernel")
        {
            byte[] data = mod.getData();

            elf = cast(Elf64Header*)data.ptr;
        }
        else
        {
            _modules[_data.numModules].base = mod.getBase() + LINEAR_MEM_BASE;
            _modules[_data.numModules].size = mod.getSize();
            
            char[] name = mod.getString();
            char[] copy = new char[name.length];
            copy[0..length] = name[0..length];
            
            _modules[_data.numModules].name = cast(ulong)copy.ptr + LINEAR_MEM_BASE;
            
            _data.numModules++;
        }
    }
    
    addUsedRegion(cast(ulong)&_data, _data.sizeof);
    addUsedRegion(cast(ulong)_mem.ptr, _mem.sizeof);
    addUsedRegion(cast(ulong)_used_mem.ptr, _used_mem.sizeof);

    if(elf !is null)
    {        
        auto pheaders = elf.getProgramHeaders();
        
        auto p = pheaders[0];
    
        CPU.pagetable = new PageTable();
        _data.L4 = cast(ulong)CPU.pagetable;

        elf.load(CPU.pagetable);
        
        gdt_setup();
        startLongMode();

        _data.elfHeader = LINEAR_MEM_BASE + cast(ulong)elf;
        
        addUsedRegion(used_base, nextPage - used_base);

        return cast(ulong)elf.entry;
    }
    else
    {
        write("\n\nError: 64 bit kernel was not loaded.  System will halt.\n");
        for(;;){}
    }
}

public void mapData(ulong virtual, size_t physical, ubyte[] data)
{
    size_t limit = FRAME_SIZE;
    
    if(data.length < FRAME_SIZE)
    {
        limit = data.length;
    }
    
    (cast(ubyte*)ptov(physical))[0..limit] = data[0..limit];
    
    Page* p = (*CPU.pagetable)[virtual];
    p.address = physical;
    p.writable = true;
    p.present = true;
    p.user = true;
    
    if(limit == FRAME_SIZE)
        mapData(virtual + FRAME_SIZE, physical + FRAME_SIZE, data[FRAME_SIZE..length]);
}

void gdt_setup()
{
    //CPU.gdt = GDT(ptov(loader.host.p_alloc()));
    CPU.gdt.init(gdt_data.ptr);
    
    NullDescriptor* n = CPU.gdt.getEntry!(NullDescriptor);
    *n = NullDescriptor();
    
    Descriptor* kc64 = CPU.gdt.getEntry!(Descriptor);
    *kc64 = Descriptor(true);
    kc64.conforming = false;
    kc64.privilege = 0;
    kc64.present = true;
    kc64.longmode = true;
    kc64.operand = false;
    
    Descriptor* kd = CPU.gdt.getEntry!(Descriptor);
    *kd = Descriptor(false);
    kd.privilege = 0;
    kd.writable = true;
    kd.present = true;
    
    Descriptor* kc = CPU.gdt.getEntry!(Descriptor);
    *kc = Descriptor(true);
    kc.conforming = false;
    kc.privilege = 0;
    kc.present = true;
    kc.longmode = false;
    kc.operand = true;
    
    CPU.gdt.install();
}

void mapDir(ulong base, ulong addr)
{
    Page[] dir = (*CPU.pagetable)[base, 1];
   
    ulong count = 0;
    
    for(size_t i=0; i<512; i++)
    {
        Page* p = &(dir[i]);
        p.address = addr + count;
        p.writable = true;
        p.present = true;
        p.user = false;
        
        count += FRAME_SIZE;
    }
}

void startLongMode()
{
    CPU.enablePAE();
    CPU.enableWP();

    writeln("Identity mapping low memory");
    mapDir(0x00000000, 0x00000000);
    mapDir(0x00200000, 0x00200000);
    mapDir(0x00400000, 0x00400000);
    mapDir(0x00600000, 0x00600000);

	writefln("Linear mapping physical memory to %#X00000000", LINEAR_MEM_BASE>>32);
	
	// Map to twice the upper limit of memory used.  Need to leave enough memory mapped
	// to set up the paging system in the kernel.  After that point, linear-mapped 
	// memory can be demand paged.
    for(ulong c = 0; c < 2*nextPage; c += 0x200000)
    {
	    mapDir(LINEAR_MEM_BASE + c, c);
	}
	
    CPU.enableLongMode();
    CPU.enablePaging();
}

public void addUsedRegion(size_t base, size_t size)
{
    _used_mem[_data.numUsedRegions].base = base;
    _used_mem[_data.numUsedRegions].size = size;
    _data.numUsedRegions++;
}

public void addMemoryRegion(size_t base, size_t size, size_t type)
{
    _mem[_data.numMemoryRegions].base = base;
    _mem[_data.numMemoryRegions].size = size;
    _mem[_data.numMemoryRegions].type = type;
    _data.numMemoryRegions++;
}

ulong readMemInfo(MultibootInfo* boot)
{
    ulong base;
    ulong length;

    size_t size = boot.getMemoryMapSize();
    MemoryMap* region = boot.getMemoryMap();

    while(cast(uint)region < cast(uint)boot.getMemoryMap() + size)
    {        
        addMemoryRegion(region.getBase(), region.getLength(), region.getType());

        region = region.next();
    }

	return 0;
}
