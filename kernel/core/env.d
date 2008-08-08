/**
 * Global objects, structures, and utilities
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.core.env;

import util.arch.cpu;

import util.spec.elf64;

import std.stdio;
import std.string;
import std.demangle;

import kernel.dev.screen;
import kernel.dev.kb;
import kernel.dev.timer;

import kernel.mem.virtual;

import kernel.task.scheduler;

import kernel.core.event;
import kernel.core.interrupt;

/// Memory range for physical memory (only support 4GB for now to allow for bitmap allocator)
const Range PHYSICAL_MEM = Range(0, 0x100000000);

/// Memory range for linear-mapped physical memory
const Range LINEAR_MEM = Range(0xFFFF830000000000, 0xFFFF830000000000 + 0x100000000);

/// Memory range for allocation of kernel-mode thread stacks
const Range KERNEL_STACK = Range(0xFFFF810000000000, 0xFFFF820000000000);

/// Memory range for allocation of user-mode thread stacks
const Range USER_STACK = Range(0x40000000, 0x80000000);

/// Memory range for the kernel's heap
const Range KERNEL_HEAP = Range(0xFFFF820000000000, 0xFFFF830000000000);

const ulong KERNEL_BASE = 0xFFFFFFFF80000000;

/// Base address for VGA text-mode memory
const ulong SCREEN_MEM = LINEAR_MEM.base + 0xB8000;

Screen screen;
Keyboard kb;

LoaderData* loaderData;

Scheduler scheduler;

Timer timer;

VirtualAllocator kernel_stack_mem = VirtualAllocator(KERNEL_STACK, false);

EventDomain root;

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
      
        while(rbp[1] >= KERNEL_BASE)
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
