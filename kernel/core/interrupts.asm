section .text

extern _common_interrupt
global _isr_common_stub

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

_isr_common_stub:
    PUSHL
    mov rdi, rbp
    mov rsi, rsp
    lea rax, [_common_interrupt wrt rip]
    call rax
    POPL
    add rsp, 8
    iretq
