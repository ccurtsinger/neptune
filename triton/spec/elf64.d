
module spec.elf64;

alias ulong	    Elf64_Addr;
alias ushort	Elf64_Half;
alias ulong	    Elf64_Off;
alias int		Elf64_Sword;
alias int		Elf64_Sxword;
alias uint		Elf64_Word;
alias ulong	    Elf64_Xword;
alias ubyte		Elf64_Byte;
alias ushort	Elf64_Section;

const Elf64_Word PT_NULL = 0;
const Elf64_Word PT_LOAD = 1;
const Elf64_Word PT_DYNAMIC = 2;
const Elf64_Word PT_INTERP = 3;
const Elf64_Word PT_NOTE = 4;
const Elf64_Word PT_SHLIB = 5;
const Elf64_Word PT_PHDR = 6;

const Elf64_Word SHT_NULL = 0;
const Elf64_Word SHT_PROGBITS = 1;
const Elf64_Word SHT_SYMTAB = 2;
const Elf64_Word SHT_STRTAB = 3;
const Elf64_Word SHT_NOBITS = 8;

struct Elf64Header
{
    align(1):
    Elf64_Byte[16]	ident;  ///<Identifier
    Elf64_Half	type;	    ///<Type
    Elf64_Half	machine;    ///<Machine
    Elf64_Word  ver;        ///<Format version
    Elf64_Addr  entry;	    ///<Process entry address
    Elf64_Off   phoff;	    ///<Program Header Table offset
    Elf64_Off   shoff;	    ///<Section Header Table offset
    Elf64_Word  flags;	    ///<Flags
    Elf64_Half  size;	    ///<Elf header size
    Elf64_Half  phsize;	    ///<Program header entry size
    Elf64_Half  phnum;	    ///<Number of program header entries
    Elf64_Half  shsize;	    ///<Section header entry size
    Elf64_Half  shnum;	    ///<Number of Section Header Entries
    Elf64_Half  shstrndx;   ///<Address of Section Header String Table

}

struct Elf64ProgramHeader
{
    align(1):
    Elf64_Word type;	    ///<Segment descriptor type
    Elf64_Word flags;	    ///<Flags
    Elf64_Off offset;	    ///<File offset of segment
    Elf64_Addr vAddr;	    ///<Virtual start address
    Elf64_Addr pAddr;	    ///<Physical start address
    Elf64_Xword fileSize;   ///<Byte size in file
    Elf64_Xword memSize;    ///<Byte size in memory
    Elf64_Xword algn;	    ///<Required alignment
}

struct Elf64SectionHeader
{
    align(1):
    Elf64_Word name;	    ///<Index into Section Header String Table
    Elf64_Word type;	    ///<Section type
    Elf64_Xword flags;	    ///<Flags
    Elf64_Addr addr;	    ///<Address of first byte
    Elf64_Off offset;	    ///<File offset
    Elf64_Xword size;	    ///<Section size (bytes)
    Elf64_Word link;	    ///<Table Index Link
    Elf64_Word info;	    ///<Extra Info
    Elf64_Xword algn;	    ///<Address alignment constraint
    Elf64_Xword entsize;    ///<Size of fixed-sized entries in section, or zero
}
