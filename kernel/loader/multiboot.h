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

/* The Multiboot header. */
typedef struct MultibootHeader
{
	unsigned long magic;
	unsigned long flags;
	unsigned long checksum;
	unsigned long header_addr;
	unsigned long load_addr;
	unsigned long load_end_addr;
	unsigned long bss_end_addr;
	unsigned long entry_addr;
} MultibootHeader;

/* The symbol table for a.out. */
typedef struct AOutSymbolTable
{
	unsigned long tabsize;
	unsigned long strsize;
	unsigned long addr;
	unsigned long reserved;
} AOutSymbolTable;

/* The section header table for ELF. */
typedef struct ElfHeaderTable
{
	unsigned long num;
	unsigned long size;
	unsigned long addr;
	unsigned long shndx;
} ElfHeaderTable;

/* The Multiboot information. */
typedef struct MultibootInfo
{
	unsigned long flags;
	unsigned long mem_lower;
	unsigned long mem_upper;
	unsigned long boot_device;
	unsigned long cmdline;
	unsigned long mods_count;
	unsigned long mods_addr;
	union
	{
		AOutSymbolTable aout_sym;
		ElfHeaderTable elf_sec;
	} u;
	unsigned long mmap_length;
	unsigned long mmap_addr;
} MultibootInfo;

/* The module structure. */
typedef struct MultibootModule
{
	unsigned long mod_start;
	unsigned long mod_end;
	unsigned long string;
	unsigned long reserved;
} MultibootModule;

/* The memory map. Be careful that the offset 0 is base_addr_low
but no size. */
typedef struct MemoryMap
{
	unsigned long size;
	unsigned long baseLow;
	unsigned long baseHigh;
	unsigned long lengthLow;
	unsigned long lengthHigh;
	unsigned long type;
} MemoryMap;
