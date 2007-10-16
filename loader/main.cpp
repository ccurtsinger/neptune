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

#include "multiboot.h"
#include "elf.h"
#include "type.h"
#include "util.h"

typedef struct GDTEntry
{
	uint16_t limit;
	uint16_t baseLow;
	uint8_t baseMid;
	uint16_t flags;
	uint8_t baseHigh;
} __attribute__((packed)) GDTEntry;

typedef struct GDTPtr
{
	uint16_t limit;
	uint32_t base;
} __attribute__((packed)) GDTPtr;

typedef struct LoaderData
{
	uint64_t L4;
	uint64_t usedMemBase;
	uint64_t usedMemSize;
	uint64_t lowerMemBase;
	uint64_t lowerMemSize;
	uint64_t upperMemBase;
	uint64_t upperMemSize;
	uint64_t regions;
	uint64_t memInfo;
}__attribute__((packed)) LoaderData;

typedef struct MemoryRegion
{
	uint64_t base;
	uint64_t length;
	uint64_t type;
}__attribute__((packed)) MemoryRegion;

LoaderData _data;
MemoryRegion _mem[256];
GDTPtr* _gdtp;

const uint64_t LINEAR_MEM_BASE = 0xFFFF830000000000LL;

/**
 * \brief
 * Set the Portable Address Extensions bit in cr4
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
inline void enablePAE()
{
    asm("mov %cr4, %eax");
    asm("or $0x20, %eax");
    asm("mov %eax, %cr4");
}

/**
 * \brief
 * Set the Write Protect bit in cr0
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
inline void enableWP()
{
    asm("mov %cr0, %eax");
    asm("bts $16, %eax");
    asm("mov %eax, %cr0");
}

/**
 * \brief
 * Load 0xA00000 into the paging register as the top-level directory
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
inline void installPaging(uint32_t L4)
{
    asm("mov %0, %%eax" : : "b" (L4));
    asm("mov %eax, %cr3");
}

/**
 * \brief
 * Use model-specific registers to switch on long mode
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
inline void enableLongMode()
{
    asm("mov $0xC0000080, %ecx");
    asm("rdmsr");
    asm("bts $8, %eax");
    asm("wrmsr");
}

/**
 * \brief
 * Set bit 31 of cr0 to enable paging
 *
 * \todo mark asm statements as volatile (?)
 * \todo set clobbered registers in asm
 */
inline void enablePaging()
{
    asm("mov %cr0, %eax");
    asm("bts $31, %eax");
    asm("mov %eax, %cr0");
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
void startLongMode(uint64_t pAddress, uint64_t kAddress, uint64_t kLength)
{
	uint64_t* L4 = pageDir();

	_data.L4 = (uint64_t)L4;

    enablePAE();
    enableWP();

	//Identity Map the first 8MB
    mapPages(L4, 0x00000000, 0x00000000);
    mapPages(L4, 0x00200000, 0x00200000);
    mapPages(L4, 0x00400000, 0x00400000);
    mapPages(L4, 0x00600000, 0x00600000);

	//Map 16MB to the kernel entry address, up to kernel length+2MB (just to be safe)
	uint64_t c = 0;
	while(c < kLength)
	{
		mapPages(L4, kAddress+c, pAddress + c);
		c += 0x200000;
	}

	//Map memory to the LINEAR_START base address
	c = 0;
	while(c < 0xFFD00001)
	{
		mapPages(L4, LINEAR_MEM_BASE + c, c);
		c += 0x200000;
	}

    installPaging(reinterpret_cast<uint32_t>(L4));
    enableLongMode();
    enablePaging();
}

uint64_t readMemInfo(MultibootInfo* boot)
{
	uint64_t base, length;
	MemoryMap* mem = (MemoryMap*)boot->mmap_addr;

	while((uint32_t)mem < boot->mmap_addr + boot->mmap_length)
	{
		base = ((uint64_t)mem->baseHigh)*0xFFFFFFFF + mem->baseLow;
		length = ((uint64_t)mem->lengthHigh)*0xFFFFFFFF + mem->lengthLow;

		_mem[_data.regions].base = base;
		_mem[_data.regions].length = length;
		_mem[_data.regions].type = mem->type;

		mem = (MemoryMap*)((uint32_t)mem + mem->size + sizeof(uint32_t));
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
extern "C" addr64_t _setup(MultibootInfo* boot, uint32_t magic)
{
	MultibootModule* module = (MultibootModule*)boot->mods_addr;
    Elf64Header* elf = (Elf64Header*)module->mod_start;
    Elf64ProgramHeader* pheader = (Elf64ProgramHeader*)((Elf64_Off)elf+elf->phoff);

    memcopy((uint32_t*)((Elf64_Off)elf + pheader->offset),(uint32_t*)pheader->pAddr,pheader->memSize);
    nextPage = (uint32_t)(pheader->pAddr+pheader->memSize+0x1000) & 0xFFFFF000;

    startLongMode(pheader->pAddr, pheader->vAddr,pheader->memSize);

    _data.usedMemBase = pheader->pAddr;

    _data.upperMemBase = 0x100000;
    _data.upperMemSize = 1024*boot->mem_upper;

    _data.lowerMemBase = 0x500;
    _data.lowerMemSize = 1024*boot->mem_lower;

	_data.regions = 0;
	_data.memInfo = reinterpret_cast<uint64_t>(&_mem) + LINEAR_MEM_BASE;

	readMemInfo(boot);

	_data.usedMemSize = static_cast<uint64_t>(reinterpret_cast<uint32_t>(morecore())) - _data.usedMemBase;

    return (addr64_t)elf->entry;
}
