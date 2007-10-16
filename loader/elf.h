typedef unsigned long long int	Elf64_Addr;
typedef unsigned short int		Elf64_Half;
typedef unsigned long long int	Elf64_Off;
typedef int						Elf64_Sword;
typedef long int				Elf64_Sxword;
typedef unsigned int			Elf64_Word;
typedef unsigned long long int	Elf64_Xword;
typedef unsigned char			Elf64_Byte;
typedef unsigned short int		Elf64_Section;

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

typedef struct Elf64Header
{
    Elf64_Byte	ident[16];  ///<Ident
    Elf64_Half	type;	    ///<Type
    Elf64_Half	machine;    ///<Machine
    Elf64_Word  version;    ///<Format version
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

} Elf64Header;

typedef struct Elf64ProgramHeader
{
    Elf64_Word type;	    ///<Segment descriptor type
    Elf64_Word flags;	    ///<Flags
    Elf64_Off offset;	    ///<File offset of segment
    Elf64_Addr vAddr;	    ///<Virtual start address
    Elf64_Addr pAddr;	    ///<Physical start address
    Elf64_Xword fileSize;   ///<Byte size in file
    Elf64_Xword memSize;    ///<Byte size in memory
    Elf64_Xword align;	    ///<Required alignment

} Elf64ProgramHeader;

typedef struct Elf64SectionHeader
{
    Elf64_Word name;	    ///<Index into Section Header String Table
    Elf64_Word type;	    ///<Section type
    Elf64_Xword flags;	    ///<Flags
    Elf64_Addr addr;	    ///<Address of first byte
    Elf64_Off offset;	    ///<File offset
    Elf64_Xword size;	    ///<Section size (bytes)
    Elf64_Word link;	    ///<Table Index Link
    Elf64_Word info;	    ///<Extra Info
    Elf64_Xword align;	    ///<Address alignment constraint
    Elf64_Xword entsize;    ///<Size of fixed-sized entries in section, or zero
} Elf64SectionHeader;
