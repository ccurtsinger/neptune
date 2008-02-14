/**
 * \file main.cpp
 * \brief
 * C++ code for the stub kernel loader.
 *
 * - loads the kernel from GRUB's module structure
 * - sets up paging
 * - enables long mode
 * - formats memory information to be passed to the kernel
 */

import arch.x86_64.arch;
import arch.x86_64.paging;

import spec.multiboot;
import spec.elf64;

import std.integer;
import std.stdio;
import std.mem;

import loader.host;
import loader.util;

extern(C) LoaderData _data;

PageTable* L4;
MemoryRegion[256] _mem;

struct LoaderData
{
    ulong L4;
    ulong usedMemBase;
    ulong usedMemSize;
    ulong lowerMemBase;
    ulong lowerMemSize;
    ulong upperMemBase;
    ulong upperMemSize;
    ulong regions;
    ulong memInfo;
    ulong tempData;
    ulong tempDataSize;
}

struct MemoryRegion
{
    ulong base;
    ulong length;
    ulong type;
}

extern(C) ulong _setup(MultibootInfo* boot, uint magic)
{
    Elf64Header* elf;

    clear();
    writeln("Executing 32 bit loader...");

    writefln("Boot Command: %s", boot.getCommand());

    auto modules = boot.getModules();

    writefln("Modules Loaded: %u", modules.length);

    foreach(mod; modules)
    {
        writefln("  %s", mod.getString());

        if(mod.getString() == "/boot/kernel")
        {
            byte[] data = mod.getData();

            elf = cast(Elf64Header*)data.ptr;
        }
    }

    if(elf !is null)
    {
        Elf64ProgramHeader* pheader = cast(Elf64ProgramHeader*)(cast(Elf64_Off)elf+elf.phoff);

        memcpy(cast(uint*)pheader.pAddr, cast(uint*)(cast(Elf64_Off)elf + pheader.offset), pheader.memSize);
        nextPage = cast(uint)(pheader.pAddr+pheader.memSize+0x1000) & 0xFFFFF000;

        startLongMode(pheader.pAddr, pheader.vAddr, pheader.memSize);

        _data.usedMemBase = pheader.pAddr;

        _data.upperMemBase = 0x100000;
        _data.upperMemSize = boot.getUpperMemSize();

        _data.lowerMemBase = 0x500;
        _data.lowerMemSize = boot.getLowerMemSize();

        _data.regions = 0;
        _data.memInfo = cast(ulong)(&_mem) + LINEAR_MEM_BASE;

        readMemInfo(boot);

        _data.usedMemSize = nextPage - _data.usedMemBase;

        return cast(ulong)elf.entry;
    }
    else
    {
        write("\n\nError: 64 bit kernel was not loaded.  System will halt.\n");
        for(;;){}
    }
}

void mapDir(ulong base, ulong addr)
{
    Page[] dir = (*L4)[base, 1];
    
    ulong count = 0;
    
    for(size_t i=0; i<512; i++)
    {
        Page* p = &(dir[i]);
        p.address = addr + count;
        p.writable = true;
        p.present = true;
        
        count += FRAME_SIZE;
    }
}

void startLongMode(ulong pAddress, ulong kAddress, ulong kLength)
{
	L4 = new PageTable;

	_data.L4 = cast(ulong)L4;

    enablePAE();
    enableWP();

    writeln("Identity mapping low memory");
    mapDir(0x00000000, 0x00000000);
    mapDir(0x00200000, 0x00200000);
    mapDir(0x00400000, 0x00400000);
    mapDir(0x00600000, 0x00600000);

	//Map 16MB to the kernel entry address, up to kernel length+2MB (just to be safe)
	writeln("Mapping 64 bit kernel memory");
	ulong c;
	for(c = 0; c<kLength; c += 0x200000)
	{
	    mapDir(kAddress+c, pAddress+c);
		c += 0x200000;
	}

	// Map a temporary data region for the kernel to use for setup
	writeln("Mapping temporary memory region");
	mapDir(kAddress+c, pAddress+c);
	
	_data.tempData = kAddress+c;
	_data.tempDataSize = 0x200000;

	writefln("Linear mapping physical memory to %08#X%08X", LINEAR_MEM_BASE>>32, LINEAR_MEM_BASE);
    for(c = 0; c < 0x1FEF0000; c += 0x200000)
    {
	    mapDir(LINEAR_MEM_BASE + c, c);
	}

    installPaging(cast(uint)L4);
    enableLongMode();
    enablePaging();
}

ulong readMemInfo(MultibootInfo* boot)
{
    ulong base;
    ulong length;

    size_t size = boot.getMemoryMapSize();
    MemoryMap* region = boot.getMemoryMap();

    while(cast(uint)region < cast(uint)boot.getMemoryMap() + size)
    {
        _mem[_data.regions].base = region.getBase();
        _mem[_data.regions].length = region.getLength();
        _mem[_data.regions].type = region.getType();

        _data.regions++;

        region = region.next();
    }

	return 0;
}
