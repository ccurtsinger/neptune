section .text

extern _common_interrupt

%macro PUSHL 0
	push r15
	push r14
	push r13
	push r12
	push r11
	push r10
	push r9
	push r8
	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push rax
%endmacro

%macro POPL 0
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	pop r8
	pop r9
	pop r10
	pop r11
	pop r12
	pop r13
	pop r14
	pop r15
	pop rbp
%endmacro

%macro INTR 1
global _isr%1
_isr%1:
	push 0	    ;Push dummy error code
	push rbp    ;Save the frame register
	mov rbp, %1 ;Put the interrupt number in the frame register (everything else is unsaved)
	jmp _isr_common_stub
%endmacro

%macro INTR_EC 1
global _isr%1
_isr%1:
	push rbp    ;Save the frame register
	mov rbp, %1 ;Put the interrupt number in the frame register (everything else is unsaved)
	jmp _isr_common_stub
%endmacro

_isr_common_stub:
    PUSHL
    mov rdi, rbp
    mov rsi, rsp
    lea rax, [_common_interrupt wrt rip]
    call rax
    POPL
    add rsp, 8
    iretq

INTR 0
INTR 1
INTR 2
INTR 3
INTR 4
INTR 5
INTR 6
INTR 7
INTR_EC 8
INTR 9
INTR_EC 10
INTR_EC 11
INTR_EC 12
INTR_EC 13
INTR_EC 14
INTR 15
INTR 16
INTR 17
INTR 18
INTR 19
INTR 20
INTR 21
INTR 22
INTR 23
INTR 24
INTR 25
INTR 26
INTR 27
INTR 28
INTR 29
INTR 30
INTR 31
INTR 32
INTR 33

%assign i 34
%rep 255 - 34 + 1
INTR i
%assign i i+1
%endrep
