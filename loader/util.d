/**
 * \file util.cpp
 * \brief
 * Utility functions for loader memory management
 *
 * Functions for getting physical pages and creating long mode page tables.
 */

/// Memory address of the last allocated physical page
uint nextPage;

/**
 * \brief
 * Return a pointer to the next available page in physical memory
 *
 * No effort is made to keep track of memory for freeing, as this will
 * all be overwritten by the kernel's full memory manager.
 */
ulong* morecore()
{
	nextPage += 0x1000;
	return cast(ulong*)nextPage;
}

/**
 * \brief
 * Test the present bit of a page directory/table entry
 *
 */
ulong present(ulong entry)
{
	return entry & 0x1;
}

/**
 * \brief
 * Return a pointer to a newly created page directory
 *
 * -# Call morecore() to get the next free physical memory page
 * -# Clear the entire page
 * -# Return in the form of a ulong pointer
 */
ulong* pageDir()
{
	ulong* dir = morecore();
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
void mapPages(ulong* L4, ulong vAddr, ulong pAddr)
{
	const ulong addrMask = 0x00000000FFFFF000;
	const ulong maskL2 = (cast(ulong)0x1FF)<<21;
	const ulong maskL3 = (cast(ulong)0x1FF)<<30;
	const ulong maskL4 = (cast(ulong)0x1FF)<<39;

	ulong* L3;
	ulong* L2;
	ulong* L1;
	uint index;

	//Calculate index into L4 table
	index = (vAddr & maskL4) >> 39;

	//Get L3 table if present, else create one
	if(present(L4[index]))
		L3 = cast(ulong*)cast(uint)(L4[index] & addrMask);
	else
	{
		L3 = pageDir();
		L4[index] = (cast(ulong)cast(uint)L3 & 0xFFFFFFFFFFFFF000) | 0x3;
	}

	//Calculate index into L3 table
	index = (vAddr & maskL3) >> 30;

	//Get L2 table if present, else create one
	if(present(L3[index]))
		L2 = cast(ulong*)cast(uint)(L3[index] & addrMask);
	else
	{
		L2 = pageDir();
		L3[index] = (cast(ulong)cast(uint)L2 & 0xFFFFFFFFFFFFF000) | 0x3;
	}

	//Calculate index into L2 table
	index = (vAddr & maskL2) >> 21;

	//Get L1 table if present, else create one
	if(present(L2[index]))
		L1 = cast(ulong*)cast(uint)(L2[index] & addrMask);
	else
	{
		L1 = pageDir();
		L2[index] = (cast(ulong)cast(uint)L1 & 0xFFFFFFFFFFFFF000) | 0x3;
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
int map(ulong* L4, ulong vAddr)
{
	const ulong addrMask = 0x00000000FFFFF000;
	const ulong maskL1 = (cast(ulong)0x1FF)<<12;
	const ulong maskL2 = (cast(ulong)0x1FF)<<21;
	const ulong maskL3 = (cast(ulong)0x1FF)<<30;
	const ulong maskL4 = (cast(ulong)0x1FF)<<39;

	ulong* L3;
	ulong* L2;
	ulong* L1;
	uint index;

	//Calculate index into L4 table
	index = (vAddr & maskL4) >> 39;

	//Get L3 table if present, else create one
	if(present(L4[index]))
		L3 = cast(ulong*)cast(uint)(L4[index] & addrMask);
	else
	{
		L3 = pageDir();
		L4[index] = (cast(ulong)cast(uint)L3 & 0xFFFFFFFFFFFFF000) | 0x3;
	}

	//Calculate index into L3 table
	index = (vAddr & maskL3) >> 30;

	//Get L2 table if present, else create one
	if(present(L3[index]))
		L2 = cast(ulong*)cast(uint)(L3[index] & addrMask);
	else
	{
		L2 = pageDir();
		L3[index] = (cast(ulong)cast(uint)L2 & 0xFFFFFFFFFFFFF000) | 0x3;
	}

	//Calculate index into L2 table
	index = (vAddr & maskL2) >> 21;

	//Get L1 table if present, else create one
	if(present(L2[index]))
		L1 = cast(ulong*)cast(uint)(L2[index] & addrMask);
	else
	{
		L1 = pageDir();
		L2[index] = (cast(ulong)cast(uint)L1 & 0xFFFFFFFFFFFFF000) | 0x3;
	}

	//Calculate index into L1 table
	index = (vAddr & maskL1) >> 12;

	if(present(L1[index]))
		return -1;
	else
		L1[index] = (cast(ulong)(morecore()) | 0x3);

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
void memcopy(void* src, void* dest, uint length)
{
    uint* sPtr = cast(uint*)src;
    uint* dPtr = cast(uint*)dest;

    while(sPtr < cast(uint*)(cast(uint)src+length))
    {
        *dPtr = *sPtr;
		dPtr++;
		sPtr++;
    }
}

import std.port;
import std.stdmem;
import std.integer;

private size_t cursor_x = 0;
private size_t cursor_y = 0;
private char* mem = cast(char*)0xB8000;

public void write(char c)
{
    if(c == '\n')
    {
        cursor_x = 0;
        cursor_y++;
    }
    else if(c == '\b')
    {
        if(cursor_x > 0)
        {
            cursor_x--;
        }
        else
        {
            cursor_x = 80-1;
            cursor_y--;
        }
        
        uint pos = cursor_y*80 + cursor_x;
        mem[2*pos] = ' ';
    }
    else if(c == '\t')
    {
        uint t = 4 - cursor_x%4;

        if(t == 0)
        {
            t = 4;
        }

        cursor_x += t;
    }
    else if(c != '\0')
    {
        uint pos = cursor_y * 80 + cursor_x;
        mem[2*pos] = c;
        mem[2*pos + 1] = 0xF;
        cursor_x++;
    }

    if(cursor_x >= 80)
    {
        cursor_x = 0;
        cursor_y++;
    }

    if(cursor_y >= 25)
    {
        // Copy a screen up, but offset by one line.  Move the line after the console up one (we cleared it in clear_screen())
        memcpy(mem, mem + 80 * 2, 2 * 80 * 25);
        cursor_y--;
    }

    updateCursor();
}

public void clear()
{
    ushort u = cast(ushort)(0xF + (0x0 << 4));
    u = u<<8;
    
    // Clear one line beyond the screen, so we can just copy it up to get a clean line
    memsets(cast(byte*)mem, u + ' ', 2 * 80 * (25 + 1));

    cursor_x = 0;
    cursor_y = 0;
    updateCursor();
}

private void updateCursor()
{
    uint temp = cursor_y * 80 + cursor_x;

    outp(0x3D4, 14);
    outp(0x3D5, temp >> 8);
    outp(0x3D4, 15);
    outp(0x3D5, temp);
}

public void print(char[] str)
{
    foreach(char c; str)
    {
        write(c);
    }
}

public void print(ulong i)
{
    char[16] s;
    size_t d = digits(i, 16);
    itoa(i, s.ptr, 16);
    
    print(s[0..d]);
}
