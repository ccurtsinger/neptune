/**
 * PIC control code
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.i586.pic;

version(arch_i586):

import std.port;

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

void remap_pic(ubyte base, ushort mask)
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
