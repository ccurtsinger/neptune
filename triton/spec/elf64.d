/**
 * ELF64 File data structures and utilities
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */
 
module spec.elf64;

import arch.x86_64.arch;
import arch.x86_64.paging;

import std.string;

const uint PT_NULL =      0x0;
const uint PT_LOAD =      0x1;
const uint PT_DYNAMIC =   0x2;
const uint PT_INTERP =    0x3;
const uint PT_NOTE =      0x4;
const uint PT_SHLIB =     0x5;
const uint PT_PHDR =      0x6;

const uint SHT_NULL =     0x0;
const uint SHT_PROGBITS = 0x1;
const uint SHT_SYMTAB =   0x2;
const uint SHT_STRTAB =   0x3;
const uint SHT_NOBITS =   0x8;

struct Elf64Header
{
    align(1):
    ubyte[16] ident;    ///<Identifier
    ushort	type;	    ///<Type
    ushort	machine;    ///<Machine
    uint    ver;        ///<Format version
    ulong   entry;	    ///<Process entry address
    ulong   phoff;	    ///<Program Header Table offset
    ulong   shoff;	    ///<Section Header Table offset
    uint    flags;	    ///<Flags
    ushort  size;	    ///<Elf header size
    ushort  phsize;	    ///<Program header entry size
    ushort  phnum;	    ///<Number of program header entries
    ushort  shsize;	    ///<Section header entry size
    ushort  shnum;	    ///<Number of Section Header Entries
    ushort  shstrndx;   ///<Index of section header string table section
    
    public Elf64ProgramHeader[] getProgramHeaders()
    {
        Elf64ProgramHeader* header = cast(Elf64ProgramHeader*)(cast(ulong)this+phoff);
        
        return header[0..phnum];
    }
    
    public Elf64SectionHeader[] getSectionHeaders()
    {
        Elf64SectionHeader* header = cast(Elf64SectionHeader*)(cast(ulong)this+shoff);
        
        return header[0..shnum];
    }
    
    public Elf64SectionHeader getSectionNameTable()
    {
        auto sheaders = getSectionHeaders();
        
        return sheaders[shstrndx];
    }
    
    public Elf64SectionHeader* getSection(char[] seek)
    {
        auto sheaders = getSectionHeaders();
        
        char* shstrtab = cast(char*)(getSectionNameTable().offset + cast(size_t)this);
        
        foreach(size_t i, section; sheaders)
        {
            char[] name = ctodstr(&(shstrtab[section.name]));
            
            if(name == seek)
                return &(sheaders[i]);
        }
        
        return null;
    }
    
    public Elf64SymbolTableEntry[] getSymbols()
    {
        auto symtab_section = getSection(".symtab");
        auto symtab = cast(Elf64SymbolTableEntry*)symtab_section.getBase(this);
        
        uint num = symtab_section.size;
        num /= Elf64SymbolTableEntry.sizeof;
        
        return symtab[0..num];
    }
    
    public void load(PageTable* pagetable, bool user = false)
    {
        foreach(p; getProgramHeaders())
        {
            p.load(this, pagetable, user);
        }
    }
}

struct Elf64ProgramHeader
{
    align(1):
    uint    type;	    ///<Program header type
    uint    flags;	    ///<Flags
    ulong   offset;	    ///<File offset of segment
    ulong   vAddr;	    ///<Virtual start address
    ulong   pAddr;	    ///<Physical start address
    ulong   fileSize;   ///<Byte size in file
    ulong   memSize;    ///<Byte size in memory
    ulong   algn;	    ///<Required alignment
    
    public ubyte[] getData(void* base)
    {
        return (cast(ubyte*)base + offset)[0..memSize];
    }
    
    public ulong getVirtualAddress()
    {
        return vAddr;
    }
    
    public ulong getPhysicalAddress()
    {
        return pAddr;
    }
    
    public ulong getMemorySize()
    {
        return memSize;
    }
    
    public void load(void* base, PageTable* pagetable, bool user)
    {
        ubyte[] data = getData(base);
        
        mapData(pagetable, getVirtualAddress(), data, user);
    }
}

struct Elf64SectionHeader
{
    align(1):
    uint    name;	    ///<Index into Section Header String Table
    uint    type;	    ///<Section type
    ulong   flags;	    ///<Flags
    ulong   addr;	    ///<Address of first byte
    ulong   offset;	    ///<File offset
    ulong   size;	    ///<Section size (bytes)
    uint    link;	    ///<Table Index Link
    uint    info;	    ///<Extra Info
    ulong   algn;	    ///<Address alignment constraint
    ulong   entsize;    ///<Size of fixed-sized entries in section, or zero
    
    public void* getBase(void* base)
    {
        return cast(void*)(offset + cast(size_t)base);
    }
}

struct Elf64SymbolTableEntry
{
    ushort  name;       ///<Index into string table
    ubyte   info;       ///<Type and binding infor
    ubyte   reserved;
    ushort  shndx;      ///<Section index
    ulong   value;	    ///<Symbol value
    ulong   size;	    ///<Size of associated object
}

private void mapData(PageTable* pagetable, ulong virtual, ubyte[] data, bool user)
{
    size_t limit = FRAME_SIZE;
    
    if(data.length < FRAME_SIZE)
    {
        limit = data.length;
    }
    
    ulong page = _d_palloc();
    
    (cast(ubyte*)ptov(page))[0..limit] = data[0..limit];
    
    Page* p = (*pagetable)[virtual];
    p.address = page;
    p.writable = true;
    p.present = true;
    p.user = user;
    
    if(limit == FRAME_SIZE)
        mapData(pagetable, virtual + FRAME_SIZE, data[FRAME_SIZE..length], user);
}
