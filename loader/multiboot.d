/* multiboot.h - the header for Multiboot */
/* Copyright (C) 1999, 2001  Free Software Foundation, Inc.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. */

module loader.multiboot;

import std.bitarray;

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

/* The Multiboot information. */
struct MultibootInfo
{
	uint flags;
	uint mem_lower;
	uint mem_upper;
	uint boot_device;
	uint cmdline;
	uint mods_count;
	uint mods_addr;
    ElfHeaderTable elf_sec;
	uint mmap_length;
	uint mmap_addr;
	
	bool hasLowerMem()
	{
	    BitArray b = BitArray(&mem_lower, 64);
	    
	    return b[0];
	}
}

/* The module structure. */
struct MultibootModule
{
	uint mod_start;
	uint mod_end;
	uint string;
	uint reserved;
}

/* The memory map. Be careful that the offset 0 is base_addr_low
but no size. */
struct MemoryMap
{
	uint size;
	uint baseLow;
	uint baseHigh;
	uint lengthLow;
	uint lengthHigh;
	uint type;
}
