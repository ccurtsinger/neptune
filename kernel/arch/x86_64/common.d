/**
 * x86 architecture common operations
 *
 * Copyright: 2008 The Neptune Project
 */

module kernel.arch.x86_64.common;

import kernel.arch.x86_64.constants;
import kernel.arch.x86_64.registers;
import kernel.arch.x86_64.descriptors;
import kernel.arch.x86_64.paging;

version(arch_x86_64):

struct Context
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
	ulong flags;
	ulong rsp;
	ulong ss;
}

void disable_interrupts()
{
    asm{"cli";}
}

void enable_interrupts()
{
    asm{"sti";}
}

void set_kernel_entry_stack(size_t p)
{
    tss.ss0 = GDTSelector.KERNEL_DATA;
    tss.esp0 = p;
}

PageTable* get_page_table()
{
    return null;
}

void load_page_table(size_t p)
{
    assert(p % FRAME_SIZE == 0, "Page table must be frame aligned");
    cr3 = p & 0xFFFFF000;
}
