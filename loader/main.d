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

import loader.multiboot;
import loader.elf;
import loader.util;

import std.integer;

struct GDTEntry
{
    align(1):
    ushort limit;
    ushort baseLow;
    ubyte baseMid;
    ushort flags;
    ubyte baseHigh;
}

struct GDTPtr
{
    align(1):
    ushort limit;
    uint base;
}

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

extern(C) LoaderData _data;
MemoryRegion[256] _mem;
GDTPtr* _gdtp;

const ulong LINEAR_MEM_BASE = 0xFFFF830000000000;

/**
 * \brief
 * Set the Portable Address Extensions bit in cr4
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
void enablePAE()
{
    asm
    {
        "mov %%cr4, %%eax";
        "or $0x20, %%eax";
        "mov %%eax, %%cr4";
    }
}

/**
 * \brief
 * Set the Write Protect bit in cr0
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
void enableWP()
{
    asm
    {
        "mov %%cr0, %%eax";
        "bts $16, %%eax";
        "mov %%eax, %%cr0";
    }
}

/**
 * \brief
 * Load 0xA00000 into the paging register as the top-level directory
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
void installPaging(uint L4)
{
    asm
    {
        "mov %[L4], %%eax" : : [L4] "Nd" L4;
        "mov %%eax, %%cr3";
    }
}

/**
 * \brief
 * Use model-specific registers to switch on long mode
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
void enableLongMode()
{
    asm
    {
        "mov $0xC0000080, %%ecx";
        "rdmsr";
        "bts $8, %%eax";
        "wrmsr";
    }
}

/**
 * \brief
 * Set bit 31 of cr0 to enable paging
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
void enablePaging()
{
    asm
    {
        "mov %%cr0, %%eax";
        "bts $31, %%eax";
        "mov %%eax, %%cr0";
    }
}

/**
 * \brief
 * Do the necessary setup for long mode paging and 64-bit addresses
 *
 * -# Enable address extensions
 * -# Create top level paging directory with pageDir()
 * -# Using mapPages():
 *  -# Identity map the first 8MB of physical memory
 *  -# Map the kernel entry address to 16MB physical
 * -# Enable paging to start long mode
 */
void startLongMode(ulong pAddress, ulong kAddress, ulong kLength)
{
	ulong* L4 = pageDir();

	_data.L4 = cast(ulong)L4;

    enablePAE();
    enableWP();

	//Identity Map the first 8MB
    mapPages(L4, 0x00000000, 0x00000000);
    mapPages(L4, 0x00200000, 0x00200000);
    mapPages(L4, 0x00400000, 0x00400000);
    mapPages(L4, 0x00600000, 0x00600000);

	//Map 16MB to the kernel entry address, up to kernel length+2MB (just to be safe)
	ulong c = 0;
	while(c < kLength)
	{
		mapPages(L4, kAddress+c, pAddress + c);
		c += 0x200000;
	}

	// Map a temporary data region for the kernel to use for setup
	mapPages(L4, kAddress+c, pAddress+c);
	_data.tempData = kAddress+c;
	_data.tempDataSize = 0x200000;

	//Map memory to the LINEAR_START base address
	c = 0;
	while(c < 0xFFD00001)
	{
		mapPages(L4, LINEAR_MEM_BASE + c, c);
		c += 0x200000;
	}

    installPaging(cast(uint)L4);
    enableLongMode();
    enablePaging();
}

ulong readMemInfo(MultibootInfo* boot)
{
	ulong base, length;
	MemoryMap* mem = cast(MemoryMap*)boot.mmap_addr;

	while(cast(uint)mem < boot.mmap_addr + boot.mmap_length)
	{
		base = (cast(ulong)mem.baseHigh)*0xFFFFFFFF + mem.baseLow;
		length = (cast(ulong)mem.lengthHigh)*0xFFFFFFFF + mem.lengthLow;

		_mem[_data.regions].base = base;
		_mem[_data.regions].length = length;
		_mem[_data.regions].type = mem.type;

		mem = cast(MemoryMap*)(cast(uint)mem + mem.size + uint.sizeof);
		_data.regions++;
	}

	return 0;
}

/**
 * \brief
 * Load the kernel and start long mode.
 *
 * Called by loader.asm
 *
 * -# Read the GRUB multiboot structure to find the kernel module
 * -# Copy the kernel to 16MB (physical)
 * -# Call startLongMode()
 * -# Return the kernel entry address
 */
extern(C) ulong _setup(MultibootInfo* boot, uint magic)
{
    static assert(Elf64Header.sizeof == 64, "Incorrect size for Elf64Header");
    static assert(Elf64ProgramHeader.sizeof == 56, "Incorrect size for Elf64ProgramHeader");
    static assert(Elf64SectionHeader.sizeof == 64, "Incorrect size for Elf64SectionHeader");
    
    clear();
    print("Executing 32 bit loader...\n");
    
    
    
	MultibootModule* mod = cast(MultibootModule*)boot.mods_addr;
    Elf64Header* elf = cast(Elf64Header*)mod.mod_start;
    Elf64ProgramHeader* pheader = cast(Elf64ProgramHeader*)(cast(Elf64_Off)elf+elf.phoff);

    memcopy(cast(uint*)(cast(Elf64_Off)elf + pheader.offset),cast(uint*)pheader.pAddr,pheader.memSize);
    nextPage = cast(uint)(pheader.pAddr+pheader.memSize+0x1000) & 0xFFFFF000;
    
    print("Entering long mode:\n");
    print("  kernel physical address: 0x");
    print(pheader.pAddr);
    print("\n  kernel virtual address: 0x");
    print(pheader.vAddr);
    print("\n  kernel memory size: 0x");
    print(pheader.memSize);
    print("\n");

    startLongMode(pheader.pAddr, pheader.vAddr, pheader.memSize);

    _data.usedMemBase = pheader.pAddr;

    _data.upperMemBase = 0x100000;
    _data.upperMemSize = 1024*boot.mem_upper;

    _data.lowerMemBase = 0x500;
    _data.lowerMemSize = 1024*boot.mem_lower;

	_data.regions = 0;
	_data.memInfo = cast(ulong)(&_mem) + LINEAR_MEM_BASE;

	readMemInfo(boot);

	_data.usedMemSize = cast(ulong)(cast(uint)morecore()) - _data.usedMemBase;

    return cast(ulong)elf.entry;
}

void spin()
{
    char* c = cast(char*)0xB8000;
    while(true)
    {
        c[0]++;
    }
}
