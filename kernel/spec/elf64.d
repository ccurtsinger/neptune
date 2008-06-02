/**
 * ELF64 File data structures and utilities
 *
 * Copyright: 2008 The Neptune Project
 */
 
module spec.elf64;

import std.string;

enum ElfIdent : size_t
{
    MAG0 = 0,
    MAG1 = 1,
    MAG2 = 2,
    MAG3 = 3,
    CLASS = 4,
    DATA = 5,
    VERSION = 6,
    OSABI = 7,
    ABIVERSION = 8,
}

enum ElfClass : ubyte
{
    ELF32 = 1,
    ELF64 = 2
}

enum ElfData : ubyte
{
    LSB = 1,
    MSB = 2
}

enum OSABI : ubyte
{
    SYSV = 0,
    HPUX = 1,
    STANDALONE = 255
}

enum ElfType : ushort
{
    NONE = 0,
    REL = 1,
    EXEC = 2,
    DYN = 3,
    CORE = 4
}

enum ProgramHeaderType : uint
{
    NULL = 0,
    LOAD = 1,
    DYNAMIC = 2,
    INTERP = 3,
    NOTE = 4,
    SHLIB = 5,
    PHDR = 6
}

enum ProgramHeaderFlags : uint
{
    X = 0x1,
    W = 0x2,
    R = 0x4
}

enum SectionHeaderType : uint
{
    NULL = 0,
    PROGBITS = 1,
    SYMTAB = 2,
    STRTAB = 3,
    RELA = 4,
    HASH = 5,
    DYNAMIC = 6,
    NOTE = 7,
    NOBITS = 8,
    REL = 9,
    SHLIB = 10,
    DYNSYM = 11
}

enum SectionHeaderFlags : ulong
{
    W = 1,
    A = 2,
    X = 4
}

enum RelocationType : ulong
{
    // A = addend
    // B = base address of shared object
    // G = offset into GOT of symbol's entry
    // GOT = address of GOT
    // L = address of PLT entry for symbol
    // P = offset
    // S = value of symbol
    // Z = size of symbol
    
    R_X86_64_NONE = 0,              // none
    R_X86_64_64 = 1,                // S + A
    R_X86_64_PC32 = 2,              // S + A - P
    R_X86_64_GOT32 = 3,             // G + A
    R_X86_64_PLT32 = 4,             // L + A - P
    R_X86_64_COPY = 5,              // none
    R_X86_64_GLOB_DAT = 6,          // S
    R_X86_64_JUMP_SLOT = 7,         // S
    R_X86_64_RELATIVE = 8,          // B + A
    R_X86_64_GOTPCREL = 9,          // G + GOT + A - P
    R_X86_64_32 = 10,               // S + A
    R_X86_64_32S = 11,              // S + A
    R_X86_64_16 = 12,               // S + A
    R_X86_64_PC16 = 13,             // S + A - P
    R_X86_64_8 = 14,                // S + A
    R_X86_64_PC8 = 15,              // S + A - P
    R_X86_64_DTPMOD64 = 16,
    R_X86_64_DTPOFF64 = 17,
    R_X86_64_TPOFF64 = 18,
    R_X86_64_TLSGD = 19,
    R_X86_64_TLSLD = 20,
    R_X86_64_DTPOFF32 = 21,
    R_X86_64_GOTTPOFF = 22,
    R_X86_64_TPOFF32 = 23,
    R_X86_64_PC64 = 24,             // S + A - P
    R_X86_64_GOTOFF64 = 25,         // S + A - GOT
    R_X86_64_GOTPC32 = 26,          // GOT + A - P
    R_X86_64_SIZE32 = 32,           // Z + A
    R_X86_64_SIZE64 = 33,           // Z + A
    R_X86_64_GOTPC32_TLSDESC = 34,
    R_X86_64_TLSDESC_CALL = 35,
    R_X86_64_TLSDESC = 36,
}

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
    
    public bool valid()
    {
        return checkMagicNumbers() && is64Bit() && !isLittleEndian() && isCurrentVersion() && getABI() == OSABI.SYSV && getABIVersion() == 0 && isAMD64();
    }
    
    public bool checkMagicNumbers()
    {
        return ident[ElfIdent.MAG0] == 0x7f && ident[ElfIdent.MAG1] == cast(ubyte)'E' && ident[ElfIdent.MAG2] == cast(ubyte)'L' && ident[ElfIdent.MAG3] == cast(ubyte)'F';
    }
    
    public bool is64Bit()
    {
        return ident[ElfIdent.CLASS] == ElfClass.ELF64;
    }
    
    public bool isLittleEndian()
    {
        return ident[ElfIdent.CLASS] == ElfData.LSB;
    }
    
    public bool isCurrentVersion()
    {
        return ident[ElfIdent.VERSION] == 1 && ver == 1;
    }
    
    public OSABI getABI()
    {
        return cast(OSABI)ident[ElfIdent.OSABI];
    }
    
    public ubyte getABIVersion()
    {
        return ident[ElfIdent.ABIVERSION];
    }
    
    public bool isExecutable()
    {
        return type == ElfType.EXEC;
    }
    
    public bool isLibrary()
    {
        return type == ElfType.DYN;
    }
    
    public bool isAMD64()
    {
        return machine == 0x3E;
    }
    
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
    
    public Elf64SectionHeader getSectionNameSection()
    {
        auto sheaders = getSectionHeaders();
        
        return sheaders[shstrndx];
    }
    
    public Elf64SectionHeader* getSection(char[] seek)
    {
        auto sheaders = getSectionHeaders();
        
        auto shstrtab = Elf64StringTable(getSection(shstrndx).getData(this));
        
        foreach(size_t i, section; sheaders)
        {
            char[] name = shstrtab[section.name];
            
            if(name == seek)
                return &(sheaders[i]);
        }
        
        return null;
    }
    
    public Elf64SectionHeader* getSection(size_t num)
    {
        auto sheaders = getSectionHeaders();
        
        if(num < sheaders.length)
            return &sheaders[num];
        
        return null;
    }
    
    public Elf64Rela[] getRelocations(char[] section)
    {
        Elf64SectionHeader* rela = getSection(section);
        
        size_t relocations = (cast(size_t)rela.size)/Elf64Rela.sizeof;
        
        return (cast(Elf64Rela*)(cast(ulong)this + rela.offset))[0..relocations];
    }
    
    /*public void load(PageTable* pagetable, bool user = false)
    {
        foreach(p; getProgramHeaders())
        {
            p.load(this, pagetable, user);
        }
    }*/
    
    /*public size_t runtimeLink(size_t plt_index)
    {
        // Find the PLT relocation table
        auto rela_plt_section = getSection(".rela.plt");
        Elf64Rela[] rela_plt = cast(Elf64Rela[])rela_plt_section.getData(this);
        
        // Get the symbol table for PLT relocations
        auto symtab_section = getSection(rela_plt_section.getLink());
        auto symtab = cast(Elf64Symbol[])symtab_section.getData(this);
        
        // Get the string table for PLT relocations
        auto strtab_section = getSection(symtab_section.getLink());
        auto strtab = Elf64StringTable(strtab_section.getData(this));
        
        // Get the name of the symbol to locate (currently unused)
        char[] symbol = strtab[symtab[rela_plt[plt_index].getSymbolIndex()].name];
        
        writefln("dynamic linker resolving symbol '%s' (%u)", symbol, plt_index);
        
        // Set the value at the relocation's offset to the desired function
        if(plt_index == 0)
        {
            rela_plt[plt_index].setValue(&syscall_1);
        }
        else if(plt_index == 1)
        {
            rela_plt[plt_index].setValue(&syscall_2);
        }
        
        // Return the address of the function so it can be called
        return rela_plt[plt_index].getValue();
    }*/
}

/*public ulong syscall_1()
{
    writeln("syscall_1()");
    return 0xDEF;
}

public ulong syscall_2()
{
    writeln("syscall_2()");
    return 0x123;
}*/

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
    
    public ProgramHeaderType getType()
    {
        return cast(ProgramHeaderType)type;
    }
    
    public char[] getTypeName()
    {
        ProgramHeaderType type = getType();
        
        if(type == ProgramHeaderType.NULL)
            return "NULL";
        else if(type == ProgramHeaderType.LOAD)
            return "LOAD";
        else if(type == ProgramHeaderType.DYNAMIC)
            return "DYNAMIC";
        else if(type == ProgramHeaderType.INTERP)
            return "INTERP";
        else if(type == ProgramHeaderType.NOTE)
            return "NOTE";
        else if(type == ProgramHeaderType.SHLIB)
            return "SHLIB";
        else if(type == ProgramHeaderType.PHDR)
            return "PHDR";
        else
            return "unknown";
    }
    
    public bool isExecutable()
    {
        return (flags & ProgramHeaderFlags.X) == ProgramHeaderFlags.X;
    }
    
    public bool isWritable()
    {
        return (flags & ProgramHeaderFlags.W) == ProgramHeaderFlags.W;
    }
    
    public bool isReadable()
    {
        return (flags & ProgramHeaderFlags.R) == ProgramHeaderFlags.R;
    }
    
    public ulong getAlignment()
    {
        return algn;
    }
    
    public bool isAllocated()
    {
        return fileSize == memSize;
    }
    
    public ubyte[] getData(void* base)
    {
        return (cast(ubyte*)base + offset)[0..memSize];
    }
    
    public ulong getOffset()
    {
        return offset;
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
    
    public ulong getFileSize()
    {
        return fileSize;
    }
    
    /*public void load(void* base, PageTable* pagetable, bool user)
    {
        mapData(pagetable, getVirtualAddress(), getData(base), user);
    }*/
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
    
    public byte[] getData(void* base)
    {
        return (cast(byte*)(offset + cast(size_t)base))[0..size];
    }
    
    public void* getAddress()
    {
        return cast(void*)addr;
    }
    
    public ulong getOffset()
    {
        return offset;
    }
    
    public ulong getSize()
    {
        return size;
    }
    
    public size_t getLength()
    {
        if(entsize != 0)
            return cast(size_t)size / cast(size_t)entsize;
        
        return 0;
    }
    
    public ulong getAlignment()
    {
        return algn;
    }
    
    public ulong getLink()
    {
        return link;
    }
    
    public char[] getName(Elf64Header* elf)
    {
        auto shstrtab = Elf64StringTable(elf.getSection(elf.shstrndx).getData(elf));
        
        return shstrtab[name];
    }
    
    public SectionHeaderType getType()
    {
        return cast(SectionHeaderType)type;
    }
    
    public char[] getTypeName()
    {
        SectionHeaderType type = getType();
        
        if(type == SectionHeaderType.NULL)
            return "NULL";
        else if(type == SectionHeaderType.PROGBITS)
            return "PROGBITS";
        else if(type == SectionHeaderType.SYMTAB)
            return "SYMTAB";
        else if(type == SectionHeaderType.STRTAB)
            return "STRTAB";
        else if(type == SectionHeaderType.RELA)
            return "RELA";
        else if(type == SectionHeaderType.HASH)
            return "HASH";
        else if(type == SectionHeaderType.DYNAMIC)
            return "DYNAMIC";
        else if(type == SectionHeaderType.NOTE)
            return "NOTE";
        else if(type == SectionHeaderType.NOBITS)
            return "NOBITS";
        else if(type == SectionHeaderType.REL)
            return "REL";
        else if(type == SectionHeaderType.SHLIB)
            return "SHLIB";
        else if(type == SectionHeaderType.DYNSYM)
            return "DYNSYM";
        else
            return "unknown";
    }
    
    public bool isAllocated()
    {
        return (flags & SectionHeaderFlags.A) == SectionHeaderFlags.A;
    }
    
    public bool isWritable()
    {
        return (flags & SectionHeaderFlags.W) == SectionHeaderFlags.W;
    }
    
    public bool isExecutable()
    {
        return (flags & SectionHeaderFlags.X) == SectionHeaderFlags.X;
    }
}

struct Elf64Rela
{
    ulong offset;
    ulong info;
    ulong addend;
    
    public ulong getOffset()
    {
        return offset;
    }
    
    public RelocationType getType()
    {
        return cast(RelocationType)(info & 0xFFFFFFFF);
    }
    
    public uint getSymbolIndex()
    {
        return cast(uint)(info >> 32);
    }
    
    public byte[] getTarget(size_t size)
    {
        RelocationType type = getType();
        byte[] target;
        
        if(type == RelocationType.R_X86_64_COPY)
        {
            target = (cast(byte*)offset)[0..size];
        }
        else if(type == RelocationType.R_X86_64_GLOB_DAT)
        {
            target = (cast(byte*)offset)[0..size];
        }
        else if(type == RelocationType.R_X86_64_JUMP_SLOT)
        {
            target = (cast(byte*)offset)[0..size];
        }
        else
        {
            assert(false, "Unsupported relocation type");
            for(;;){}
        }
        
        return target;
    }
    
    public void setValue(void* data)
    {
        setValue(&data, (void*).sizeof);
    }
    
    public size_t getValue()
    {
        byte[] target = getTarget(size_t.sizeof);
        
        return *(cast(size_t*)target.ptr);
    }
    
    public void setValue(void* p, size_t size)
    {
        byte[] data = (cast(byte*)p)[0..size];
        byte[] target = getTarget(size);
        
        target[0..length] = data[0..length];
    }
}

struct Elf64StringTable
{
    private char[] strtab;
    
    public static Elf64StringTable opCall(byte[] data)
    {
        Elf64StringTable t;
        t.strtab = cast(char[])data;
        return t;
    }
    
    public char[] opIndex(size_t i)
    {
        return ctodstr(&(strtab[i]));
    }
}

struct Elf64Symbol
{
    ushort  name;       ///<Index into string table
    ubyte   info;       ///<Type and binding infor
    ubyte   reserved;
    ushort  shndx;      ///<Section index
    ulong   value;	    ///<Symbol value
    ulong   size;	    ///<Size of associated object
}

/*private void mapData(PageTable* pagetable, ulong virtual, ubyte[] data, bool user)
{
    ulong offset = virtual % FRAME_SIZE;
    size_t limit = FRAME_SIZE - offset;
    
    if(data.length < FRAME_SIZE - offset)
    {
        limit = data.length;
    }
    
    Page* p = (*pagetable)[virtual];
    
    if(!p.present)
    {
        p.address = _d_palloc();
        p.writable = true;
        p.present = true;
        p.user = user;
    }
    
    (cast(ubyte*)ptov(p.address + offset))[0..limit] = data[0..limit];
    
    if(limit == FRAME_SIZE)
        mapData(pagetable, virtual + FRAME_SIZE, data[FRAME_SIZE..length], user);
}*/
