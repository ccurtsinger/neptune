/**
 * IDT abstraction, utilities, and related constants
 *
 * Authors: Charlie Curtsinger
 * Date: January 15th, 2008
 * Version: 0.2a
 */

module arch.x86_64.idt;

import arch.x86_64.descriptor;
import std.port;

/**
 * IDT abstraction
 */
struct IDT
{
    GateDescriptor[256] data;
    
    public void init(ushort irqmask)
    {
        remapPic(32, irqmask);
    }
    
    /**
     * Return a pointer to the given entry
     */
    public GateDescriptor* opIndex(size_t index)
    {
        return &(data[index]);
    }
    
    /**
     * Load the IDT
     */
    public void install()
    {
        DTPtr idtp;
        
        idtp.limit = 256 * 16 - 1;
        idtp.address = data.ptr;

        asm
        {
            "cli";
            "lidt (%[idtp])" : : [idtp] "b" &idtp;
            "sti";
        }
    }
}

/// Master PIC port
const ubyte PIC1 = 0x20;

/// Slave PIC port
const ubyte PIC2 = 0xA0;

/// Initialization code word 1
const ubyte ICW1 = 0x11;

/// Initialization code word 4
const ubyte ICW4 = 0x01;

/// PIC interrupt acknowledgement data
const ubyte PIC_EOI = 0x20;

/**
 * Remap the PIC base IRQ and set the IRQ mask
 *
 * Params:
 *  base = base interrupt for IRQ 0
 *  mask = IRQ mask
 */
void remapPic(ubyte base = 32, ushort mask = 0x0)
{
	//Sent ICW1
	outp(PIC1, ICW1);
	outp(PIC2, ICW1);

	//Send ICW2
	outp(PIC1+1, base);
	outp(PIC2+1, base+8);

	//Send ICW3
	outp(PIC1+1, 4);
	outp(PIC2+1, 2);

	//Send ICW4
	outp(PIC1+1, ICW4);
	outp(PIC2+1, ICW4);
	
	outp(PIC1+1, cast(ubyte)(mask&0xFF));
	outp(PIC2+1, cast(ubyte)((mask>>8)&0xFF));
}
