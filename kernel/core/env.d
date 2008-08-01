/**
 * Global objects, structures, and utilities
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core.env;

import util.arch.arch;
import util.arch.cpu;

import util.spec.elf64;

import std.stdio;
import std.string;
import std.demangle;

import kernel.dev.screen;
import kernel.dev.kb;
import kernel.dev.timer;
import kernel.core.interrupt;
import kernel.task.procallocator;

Screen screen;
Keyboard kb;

InterruptScope localscope;

LoaderData* loaderData;

ProcessorAllocator procalloc;
Processor local;

Timer timer;

/**
 * Data passed from the 32 bit loader
 */
struct LoaderData
{
	ulong L4;
	
	ulong numMemoryRegions;
	MemoryRegion* memoryRegions;
	
	ulong numUsedRegions;
    MemoryRegion* usedRegions;
	
	Elf64Header* elfHeader;
	
	ulong numModules;
    LoaderModule* modules;
}

struct MemoryRegion
{
    ulong base;
    ulong size;
    ulong type;
}

struct LoaderModule
{
    char* name;
    ulong base;
    ulong size;
}

version(unwind)
{
    void stackUnwind(ulong* rsp, ulong* rbp)
    {
        size_t i=1;
      
        while(rbp[1] >= 0xFFFFFFFF80000000)
        {
            rsp = rbp;
            rbp = cast(ulong*)rsp[0];
            
            writefln("%p: %s", rsp[1], getSymbol(rsp[1]));
            
            for(size_t j=0; j<10000000; j++){}
            
            i++;
        }
    }

    char[] getSymbol(ulong address)
    {
        auto strtab_section = loaderData.elfHeader.getSection(".strtab");
        char* strtab = cast(char*)strtab_section.getBase(loaderData.elfHeader);
        
        auto symbols = loaderData.elfHeader.getSymbols();
        
        Elf64Symbol best;
        ulong best_distance = ulong.max;
        
        foreach(symbol; symbols)
        {
            // If this symbol contains the return address, print it
            if(symbol.value <= address && symbol.value + symbol.size > address)
            {
                char[] name = ctodstr(&(strtab[symbol.name]));
                
                return demangle(name);
            }
            
            // Find the nearest symbol with a non-empty name (useful for assembly functions, which define a size of 0
            if(address > symbol.value && address - symbol.value < best_distance && ctodstr(&strtab[symbol.name]) != "")
            {
                best_distance = address - symbol.value;
                best = symbol;
            }
        }
        
        // If we didn't find a match, print the closest possible symbol
        if(best_distance < ulong.max)
        {
            return ctodstr(&(strtab[best.name]));
        }
        else
        {
            return "Unknown";
        }
    }
}
