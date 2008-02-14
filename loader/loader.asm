global _loader           ; making entry point visible to linker

extern _setup, _data

;symbols from the linker script, used in the aout kludge
extern code, bss, end

;setting up the Multiboot header - see GRUB docs for details
MODULEALIGN equ  1<<0                   ; align loaded modules on page boundaries
MEMINFO     equ  1<<1                   ; provide memory map
AOUT_KLUDGE equ  1<<16
GRAPHICS    equ  1<<2

FLAGS       equ  MODULEALIGN | MEMINFO | AOUT_KLUDGE | GRAPHICS
MAGIC       equ  0x1BADB002           ; 'magic number' lets bootloader find the header
CHECKSUM    equ -(MAGIC + FLAGS)        ; checksum required

BASE equ 0x100000

section .text
align 4
MultiBootHeader:
	dd MAGIC
	dd FLAGS
	dd CHECKSUM

	dd MultiBootHeader ; these are PHYSICAL addresses
	dd code  ; start of kernel .text (code) section
	dd bss ; end of kernel .data section
	dd end   ; end of kernel BSS
	dd _loader ; kernel entry point (initial EIP)
	dd 0
	dd 800
	dd 600
	dd 32

;Use a 32K stack for the kernel
STACKSIZE equ 0x8000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BITS 32
_loader:
    mov esp, stack+STACKSIZE    ;Set up the stack
    push eax                    ;Pass the multiboot magic number to _main
    push ebx                    ;Pass the multiboot info structure to _main

;Load the Kernel and set up Long Mode
	call _setup

;Setup returns the entry address in edx:eax
	push edx
	push eax

;The stack should now be:
;  Memory Start (64 bits)
;  Memory Size (64 bits)
;  Kernel Entry Address (64 bits)

;Long jump to 64 bit code (must have a 64 bit descriptor at the 2nd GDT index)
    jmp 08h:long_start

BITS 64

long_start:
;Pop kernel entry address into rax
	pop rax

;Put loader data structure pointer into first argument
	mov rdi, _data

;Go to the 64 bit kernel
	jmp rax

;Halt the machine.  This code should never be reached
    hlt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .bss
align 32
stack:
	resb STACKSIZE	;Reserve STACKSIZE, aligned to 32 bits
