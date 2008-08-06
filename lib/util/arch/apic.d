/**
 * Local APIC Abstraction
 *
 * Copyright: 2008 The Neptune Project
 */

module util.arch.apic;

import util.arch.cpu;

const uint APIC_ID =        0x20;   // APIC ID register
const uint APIC_VER =       0x30;   // APIC Version register
const uint APIC_TPR_PRI =   0x80;   // APIC Task Priority Register
const uint APIC_ARB_PRI =   0x90;   // APIC Arbitration Priority Register
const uint APIC_PROC_PRI =  0xA0;   // APIC Processor Priority Register
const uint APIC_EOI =       0xB0;   // APIC End-Of-Interrupt Register
const uint APIC_RMT_READ =  0xC0;   // APIC Remote Read Register
const uint APIC_LOG_DEST =  0xD0;   // APIC Logical Destination Register
const uint APIC_DEST_FMT =  0xE0;   // APIC Destination Register Format
const uint APIC_SPUR_INT =  0xF0;   // APIC Spurios Interrupt Vector Register
const uint APIC_ERR_STAT =  0x280;  // APIC Error Status Register
const uint APIC_ICRLO =     0x300;  // APIC Interrupt Command Register (bits 0..31)
const uint APIC_ICRHI =     0x310;  // APIC Interrupt Command Register (bits 32..63)
const uint APIC_TIMER_LVT = 0x320;  // APIC Timer Local Vector Table
const uint APIC_THERM_LVT = 0x330;  // APIC Thermal Local Vector Table
const uint APIC_PERF_LVT  = 0x340;  // APIC Performance Counter Local Vector Table
const uint APIC_LINT0_LVT = 0x350;  // APIC Local Interrupt 0 LVT
const uint APIC_LINT1_LVT = 0x360;  // APIC Local Interrupt 1 LVT
const uint APIC_ERROR_LVT = 0x370;  // APIC Error Local Vector Table
const uint APIC_INIT_CNT =  0x380;  // APIC Timer Intial Count Register
const uint APIC_CURR_CNT =  0x390;  // APIC Timer Current Count Register
const uint APIC_TIMER_DIV = 0x3E0;  // APIC Timer Divider Configuration Register

// Extended APIC register space
const uint APIC_EXT_FEAT =  0x400;  // APIC Extended Feature Register
const uint APIC_THRCNT_INT0 = 0x500;    // APIC Threshold Count Interrupt 0 LVT Entry

// In-service Registers
const uint[8] APIC_ISR = [0x100, 0x110, 0x120, 0x130, 0x140, 0x150, 0x160, 0x170];

// Trigger-mode Registers
const uint[8] APIC_TMR = [0x180, 0x190, 0x1A0, 0x1B0, 0x1C0, 0x1D0, 0x1E0, 0x1F0];

// Interrupt Request Registers
const uint[8] APIC_IRR = [0x200, 0x210, 0x220, 0x230, 0x240, 0x250, 0x260, 0x270];

struct APIC
{
    static APIC* opCall()
    {
        ulong base = CPU.readMsr(0x1B) & 0xFFFFFFFFFFFF0000;
        
        return cast(APIC*)ptov(base);
    }
    
    public uint read(uint register)
    {
        return *(cast(uint*)(this + register));
    }
    
    public void write(uint register, uint value)
    {
        *(cast(uint*)(this + register)) = value;
    }
    
    public uint id()
    {
        return (read(APIC_ID) >> 24);
    }
    
    public uint ver()
    {
        return read(APIC_VER) & 0xFF;
    }
    
    public void setTimer(ubyte interrupt, bool periodic, uint ms)
    {
        // Set the timer divider to 128
        write(APIC_TIMER_DIV, 0xA);
        
        if(periodic)
            write(APIC_TIMER_LVT, 0x20000 + interrupt);
        else
            write(APIC_TIMER_LVT, interrupt);
        
        uint count = CPU_BUS_SPEED/128;
        count /= 1000;
        count *= ms;
        
        write(APIC_INIT_CNT, count);
    }
}
