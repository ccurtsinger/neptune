/**
 * CPU abstraction
 *
 * Authors: Charlie Curtsinger
 * Date: March 1st, 2008
 * Version: 0.3
 *
 * Copyright: 2008 Charlie Curtsinger
 */

module arch.x86_64.cpu;

import arch.x86_64.arch;
import arch.x86_64.apic;
import arch.x86_64.gdt;
import arch.x86_64.idt;
import arch.x86_64.tss;
import arch.x86_64.descriptor;
import arch.x86_64.paging;

// Assume a 1000MHz CPU Bus for now
const uint CPU_BUS_SPEED = 1000000000;

template registerProperty(char[] name)
{
    const char[] registerProperty = "static size_t " ~ name ~ "() {
        size_t value;
        asm
        {
            \"mov %%" ~ name ~ ", %[value]\" : [value] \"=a\" value;
        }
        return value; 
    }
    
    static void " ~ name ~ "(size_t value) {
        asm
        {
            \"mov %[value], %%" ~ name ~ "\" : : [value] \"a\" value;
        }
    }";
}

struct CPU
{
    APIC* apic;
    GDT gdt;
    IDT idt;
    TSS tss;
    PageTable* pagetable;
    
    static void halt()
    {
        asm{ "hlt"; }
    }
    
    static ulong readMsr(uint msr)
    {
        uint hi;
        uint lo;
        
        asm
        {
            "rdmsr" : "=d" hi, "=a" lo : "c" msr;
        }
        
        ulong data = hi;
        data = data<<32;
        data |= lo;
        
        return data;
    }
    
    static void writeMsr(uint msr, ulong data)
    {
        uint hi = cast(uint)(data>>32);
        uint lo = cast(uint)(data & 0xFFFFFFFF);
        
        asm
        {
            "wrmsr" : : "d" hi, "a" lo, "c" msr;
        }
    }
    
    static void enableInterrupts()
    {
        asm{"sti";}
    }
    
    static void disableInterrupts()
    {
        asm{"cli";}
    }
    
    void loadPageDir()
    {
        cr3 = vtop(pagetable);
    }
    
    version(x86_64)
    {
        mixin(registerProperty!("rsp"));
        mixin(registerProperty!("rbp"));
        mixin(registerProperty!("rax"));
        mixin(registerProperty!("rbx"));
        mixin(registerProperty!("rcx"));
        mixin(registerProperty!("rdx"));
        mixin(registerProperty!("rdi"));
        mixin(registerProperty!("rsi"));
        mixin(registerProperty!("r8"));
        mixin(registerProperty!("r9"));
        mixin(registerProperty!("r10"));
        mixin(registerProperty!("r11"));
        mixin(registerProperty!("r12"));
        mixin(registerProperty!("r13"));
        mixin(registerProperty!("r14"));
        mixin(registerProperty!("r15"));
    }
    else version(i586)
    {
        static void enablePAE()
        {
            cr4 = cr4 | 0x20;
        }
        
        static void enableWP()
        {
            cr0 = cr0 | 0x10000;
        }
        
        static void enableLongMode()
        {
            writeMsr(MSR_EFER, readMsr(MSR_EFER) | 0x100);
        }
        
        static void enablePaging()
        {
            cr0 = cr0 | 0x80000000;
        }
        
        mixin(registerProperty!("esp"));
        mixin(registerProperty!("ebp"));
        mixin(registerProperty!("eax"));
        mixin(registerProperty!("ebx"));
        mixin(registerProperty!("ecx"));
        mixin(registerProperty!("edx"));
        mixin(registerProperty!("edi"));
        mixin(registerProperty!("esi"));
    }
    
    mixin(registerProperty!("cr0"));
    mixin(registerProperty!("cr1"));
    mixin(registerProperty!("cr2"));
    mixin(registerProperty!("cr3"));
    mixin(registerProperty!("cr4"));
    mixin(registerProperty!("ss"));
}

const uint MSR_TSC = 0x0010;          // Time-Stamp Counter

const uint MSR_APIC_BASE = 0x001B;    // Base address of the Local APIC

const uint MSR_MTRR_CAP = 0x00FE;     // Memory typing cap
// TODO: add MTRR registers 0x0200 through 0x02FF

const uint MSR_SYSENTER_CS = 0x0174;  // Sysenter code segment selector
const uint MSR_SYSENTER_ESP = 0x0175; // Sysenter stack pointer
const uint MSR_SYSENTER_EIP = 0x0176; // Sysenter instruction pointer

const uint MSR_MCG_CAP = 0x0179;      // Machine check cap
const uint MSR_MCG_STATUS = 0x017A;   // Machine check status
const uint MSR_MCG_CTL = 0x017B;      // Machine check control

// Machine check control registers
const uint MSR_MC0_CTL = 0x0400;
const uint MSR_MC1_CTL = 0x0404;
const uint MSR_MC2_CTL = 0x0408;
const uint MSR_MC3_CTL = 0x040C;
const uint MSR_MC4_CTL = 0x0410;
const uint MSR_MC5_CTL = 0x0414;

// Machine check status registers
const uint MSR_MC0_STATUS = 0x0401;
const uint MSR_MC1_STATUS = 0x0405;
const uint MSR_MC2_STATUS = 0x0409;
const uint MSR_MC3_STATUS = 0x040D;
const uint MSR_MC4_STATUS = 0x0411;
const uint MSR_MC5_STATUS = 0x0415;

// Machine check address registers
const uint MSR_MC0_ADDR = 0x0402;
const uint MSR_MC1_ADDR = 0x0406;
const uint MSR_MC2_ADDR = 0x040A;
const uint MSR_MC3_ADDR = 0x040E;
const uint MSR_MC4_ADDR = 0x0412;
const uint MSR_MC5_ADDR = 0x0416;

// Machine check error information registers
const uint MSR_MC0_MISC = 0x0403;
const uint MSR_MC1_MISC = 0x0407;
const uint MSR_MC2_MISC = 0x040B;
const uint MSR_MC3_MISC = 0x040F;
const uint MSR_MC4_MISC = 0x0413;
const uint MSR_MC5_MISC = 0x0417;

// Software Debug registers
const uint MSR_DEBUG_CTL = 0x01D9;
const uint MSR_LAST_BRANCH_FROM_IP = 0x01DB;
const uint MSR_LAST_BRANCH_TO_IP = 0x01DC;
const uint MSR_LAST_EXCEPTION_FROM_IP = 0x01DD;
const uint MSR_LAST_EXCEPTION_TO_IP = 0x01DE;

// Extended features
const uint MSR_EFER = 0xC0000080;

// Syscall MSRs
const uint MSR_STAR = 0xC0000081;       // Syscall legacy cs, ss, and stack register
const uint MSR_LSTAR = 0xC0000082;      // Syscall long mode instruction pointer
const uint MSR_CSTAR = 0xC0000083;      // Syscall legacy instruction pointer
const uint MSR_SF_MASK = 0xC0000084;    // Syscall flags mask
