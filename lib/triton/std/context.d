/**
 * Support for access and operations on saved processor context
 *
 * Copyright: 2008 The Neptune Project
 */

module std.context;

struct Context
{
    align(1):
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
	
	version(x86_64)
	{
        public void load()
        {
            rsp -= 8;
            *(cast(ulong*)rsp) = rip;
            
            cs = rax;
            
            asm
            {
                "mov %[stack], %%rsp" : : [stack] "Nd" this;
                "pop %%rax";
                "pop %%rbx";
                "pop %%rcx";
                "pop %%rdx";
                "pop %%rsi";
                "pop %%rdi";
                "pop %%r8";
                "pop %%r9";
                "pop %%r10";
                "pop %%r11";
                "pop %%r12";
                "pop %%r13";
                "pop %%r14";
                "pop %%r15";
                "pop %%rbp";
                
                // Skip over the error, rip, and cs fields
                "pop %%rax";
                "pop %%rax";
                "pop %%rax";
                
                "popf";
                "pop %%rsp";
                
                "ret";
            }
        }
	}
}
