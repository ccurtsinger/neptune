module kernel.arch.IDT;

import std.port;

import kernel.arch.Descriptor;

struct IDT
{
    GateDescriptor[256] data;
    
    public GateDescriptor* opIndex(size_t index)
    {
        return &(data[index]);
    }
    
    public void install()
    {
        DTPtr idtp;
        
        idtp.limit = 256 * 16 - 1;
        idtp.address = data.ptr;
        
        remapPic(32, 0xFFFF);

        asm
        {
            "cli";
            "lidt (%[idtp])" : : [idtp] "b" &idtp;
            "sti";
        }
    }
}

const ubyte PIC1 = 0x20;
const ubyte PIC2 = 0xA0;
const ubyte ICW1 = 0x11;
const ubyte ICW4 = 0x01;
const ubyte PIC_EOI = 0x20;

struct InterruptStack
{
	ulong rax;
	ulong rbx;
	ulong rcx;
	ulong rdx;
	ulong rsi;
	ulong rdi;
	ulong r8;
	ulong r9;
	ulong r10;
	ulong r11;
	ulong r12;
	ulong r13;
	ulong r14;
	ulong r15;
	ulong rbp;
	ulong error;
	ulong rip;
	ulong cs;
	ulong rflags;
	ulong rsp;
	ulong ss;
}

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

	//Disable all but IRQ 1
	outp(PIC1+1, cast(ubyte)(mask&0xFF));
	outp(PIC2+1, cast(ubyte)((mask>>8)&0xFF));
}
