/**
 * \file util.cpp
 * \brief
 * Utility functions for loader memory management
 *
 * Functions for getting physical pages and creating long mode page tables.
 */

#include "type.h"

/// Memory address of the last allocated physical page
uint32_t nextPage;

/**
 * \brief
 * Return a pointer to the next available page in physical memory
 *
 * No effort is made to keep track of memory for freeing, as this will
 * all be overwritten by the kernel's full memory manager.
 */
uint64_t* morecore()
{
	nextPage += 0x1000;
	return (uint64_t*)nextPage;
}

/**
 * \brief
 * Test the present bit of a page directory/table entry
 *
 */
inline uint64_t present(uint64_t entry)
{
	return entry & 0x1;
}

/**
 * \brief
 * Return a pointer to a newly created page directory
 *
 * -# Call morecore() to get the next free physical memory page
 * -# Clear the entire page
 * -# Return in the form of a uint64_t pointer
 */
uint64_t* pageDir()
{
	uint64_t* dir = morecore();
	int i;

	for(i=0;i<512;i++)
	{
		dir[i] = 0;
	}

	return dir;
}

/**
 * \brief
 * Map 2MB of virtual addresses to physical addresses in the specified top-level page directory
 *
 * Page directory entries are used to navigate to the correct page table.
 * Tables and directories will be created as needed, but existing directories
 * will never be overwritten.
 */
void mapPages(uint64_t* L4, addr64_t vAddr, addr64_t pAddr)
{
	const uint64_t addrMask = 0x00000000FFFFF000;
	const uint64_t maskL2 = 0x1FFLL<<21;
	const uint64_t maskL3 = 0x1FFLL<<30;
	const uint64_t maskL4 = 0x1FFLL<<39;

	uint64_t* L3;
	uint64_t* L2;
	uint64_t* L1;
	uint32_t index;

	//Calculate index into L4 table
	index = (vAddr & maskL4) >> 39;

	//Get L3 table if present, else create one
	if(present(L4[index]))
		L3 = (uint64_t*)(uint32_t)(L4[index] & addrMask);
	else
	{
		L3 = pageDir();
		L4[index] = ((uint64_t)(uint32_t)L3 & 0xFFFFFFFFFFFFF000LL) | 0x3;
	}

	//Calculate index into L3 table
	index = (vAddr & maskL3) >> 30;

	//Get L2 table if present, else create one
	if(present(L3[index]))
		L2 = (uint64_t*)(uint32_t)(L3[index] & addrMask);
	else
	{
		L2 = pageDir();
		L3[index] = ((uint64_t)(uint32_t)L2 & 0xFFFFFFFFFFFFF000LL) | 0x3;
	}

	//Calculate index into L2 table
	index = (vAddr & maskL2) >> 21;

	//Get L1 table if present, else create one
	if(present(L2[index]))
		L1 = (uint64_t*)(uint32_t)(L2[index] & addrMask);
	else
	{
		L1 = pageDir();
		L2[index] = ((uint64_t)(uint32_t)L1 & 0xFFFFFFFFFFFFF000LL) | 0x3;
	}

	//Map the entire L1 page directory
	int i;
	for(i=0;i<512;i++)
	{
		L1[i] = (pAddr | 0x3);

		pAddr += 0x1000;
	}
}

/**
 * \brief
 * Map a single page of physical memory to the specified virtual address
 *
 * Page directory entries are used to navigate to the correct page table.
 * Tables and directories will be created as needed, but existing directories
 * will never be overwritten.
 */
int map(uint64_t* L4, addr64_t vAddr)
{
	const uint64_t addrMask = 0x00000000FFFFF000;
	const uint64_t maskL1 = 0x1FFLL<<12;
	const uint64_t maskL2 = 0x1FFLL<<21;
	const uint64_t maskL3 = 0x1FFLL<<30;
	const uint64_t maskL4 = 0x1FFLL<<39;

	uint64_t* L3;
	uint64_t* L2;
	uint64_t* L1;
	uint32_t index;

	//Calculate index into L4 table
	index = (vAddr & maskL4) >> 39;

	//Get L3 table if present, else create one
	if(present(L4[index]))
		L3 = (uint64_t*)(uint32_t)(L4[index] & addrMask);
	else
	{
		L3 = pageDir();
		L4[index] = ((uint64_t)(uint32_t)L3 & 0xFFFFFFFFFFFFF000LL) | 0x3;
	}

	//Calculate index into L3 table
	index = (vAddr & maskL3) >> 30;

	//Get L2 table if present, else create one
	if(present(L3[index]))
		L2 = (uint64_t*)(uint32_t)(L3[index] & addrMask);
	else
	{
		L2 = pageDir();
		L3[index] = ((uint64_t)(uint32_t)L2 & 0xFFFFFFFFFFFFF000LL) | 0x3;
	}

	//Calculate index into L2 table
	index = (vAddr & maskL2) >> 21;

	//Get L1 table if present, else create one
	if(present(L2[index]))
		L1 = (uint64_t*)(uint32_t)(L2[index] & addrMask);
	else
	{
		L1 = pageDir();
		L2[index] = ((uint64_t)(uint32_t)L1 & 0xFFFFFFFFFFFFF000LL) | 0x3;
	}

	//Calculate index into L1 table
	index = (vAddr & maskL1) >> 12;

	if(present(L1[index]))
		return -1;
	else
		L1[index] = (reinterpret_cast<uint64_t>(morecore()) | 0x3);

	return 0;
}

/**
 * \brief
 * Copy a block of memory starting at the lowest address
 *
 * \note Will overwrite the end of the object if its end
 * is beyond the destination address.  This should be checked, or
 * the function should be set up to copy from the highest address first.
 */
void memcopy(void* src, void* dest, uint32_t length)
{
    uint32_t* sPtr = (uint32_t*)src;
    uint32_t* dPtr = (uint32_t*)dest;

    while(sPtr < (uint32_t*)((uint32_t)src+length))
    {
        *dPtr = *sPtr;
		dPtr++;
		sPtr++;
    }
}
