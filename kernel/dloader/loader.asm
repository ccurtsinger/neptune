global _loader           ; making entry point visible to linker

extern _setup, _data

;symbols from the linker script, used in the aout kludge
extern code, bss, end

;setting up the Multiboot header - see GRUB docs for details
MODULEALIGN equ  1<<0                   ; align loaded modules on page boundaries
MEMINFO     equ  1<<1                   ; provide memory map
AOUT_KLUDGE equ  1<<16

FLAGS       equ  MODULEALIGN | MEMINFO | AOUT_KLUDGE ; this is the Multiboot 'flag' field
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

;Use a 32K stack for the kernel
STACKSIZE equ 0x8000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BITS 32
_loader:
    mov esp, stack+STACKSIZE    ;Set up the stack
    push eax                    ;Pass the multiboot magic number to _main
    push ebx                    ;Pass the multiboot info structure to _main

    lgdt [gdt_ptr]		;Install the GDT

;Set all the segments to Kernel space
    mov ax,KERNEL_DATA
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov gs,ax
    jmp KERNEL_CODE:in_seg
    in_seg:

;Load the Kernel and set up Long Mode
	call _setup

;Setup returns the entry address in edx:eax
	push edx
	push eax

;The stack should now be:
;  Memory Start (64 bits)
;  Memory Size (64 bits)
;  Kernel Entry Address (64 bits)

;Long jump to 64 bit code
    jmp KERNEL_CODE64:long_start

BITS 64

long_start:
;Pop kernel entry address into rax
	pop rax

	mov rdi, _data

;Go to the 64 bit kernel
	jmp rax

;Halt the machine.  This code should never be reached
    hlt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data

; NOTE: This GDT is only used in the loader, so no user segments are needed

;GDT descriptor information:
;   P indicates present (0 is non present)
;   DPL of 0 is kernel mode, 3 is user mode
;   S is 0 for TSS, Interrupt gate, etc.., 1 for Code/data/stack
;   Type: (bits from right to left)
;	bit 0: 1 means segment has been accessed already
;	bit 1: For data, 0 means r, 1 means r/w. For code, 0 means !r, 1 means readable
;	bit 2: If code segment, 1 means underpriveleged programs to access this segment
;	    at their privelege level.  For data segment, 0 means expand-up stack (standard)
;	bit 3: If S=1, 1 means code segment, 0 means data segment
;   G is granularity: 0 means size in byte, 1 means size in 4K pages
;   D/B: for code segments, 1 means 32-bit addresses, 0 means 16-bit
;	    for data, 1 means 32-bit stack pointer, 0 is 16-bit
;   L: if L=1, D must be 0 (long mode).
;   AVL is available for any use
;   Size sets top of segment size (4gigs means G=1, size=1111)

gdt:
    ;NULL descriptor
    dw 0
    dw 0
    db 0
    db 0
    db 0
    db 0

KERNEL_CODE64 equ ($ - gdt)
    ;Kernel code descriptor
    dw 0FFFFh		;Limit
    dw 0			;Lowest two bytes of base
    db 0			;Third byte of base
    db 10011010b	;P (1 bit), DP (2 bits), S (1 bit), Type(4 bits)
    db 10101111b	;G(1 bit), D/B (1 bit), L (1 bit), AVL (1 bit), Size (4 bits)
    db 0			;Fourth byte of base

KERNEL_DATA equ ($ - gdt)
    ;Kernel data descriptor
    dw 0FFFFh		;Limit
    dw 0			;Lowest two bytes of base
    db 0			;Third byte of base
    db 10010010b	;P (1 bit), DP (2 bits), S (1 bit), Type(4 bits)
    db 11001111b	;G(1 bit), D/B (1 bit), L (1 bit), AVL (1 bit), Size (4 bits)
    db 0			;Fourth byte of base

KERNEL_CODE equ ($ - gdt)
    ;Kernel code descriptor
    dw 0FFFFh		;Limit
    dw 0			;Lowest two bytes of base
    db 0			;Third byte of base
    db 10011010b	;P (1 bit), DP (2 bits), S (1 bit), Type(4 bits)
    db 11001111b	;G(1 bit), D/B (1 bit), L (1 bit), AVL (1 bit), Size (4 bits)
    db 0			;Fourth byte of base

gdt_end:

;Structure to be loaded into the gdtr register
gdt_ptr:
    dw gdt_end - gdt - 1
    dd gdt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .bss
align 32
stack:
	resb STACKSIZE	;Reserve STACKSIZE, aligned to 32 bits
