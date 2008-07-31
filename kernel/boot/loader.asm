BITS 64

global _loader           ; making entry point visible to linker

extern _startup;, _exit
extern _Dmodule_ref
extern _isrtable

section .text
_loader:
    cli
	; Initialize the stack pointer
    lea rsp, [stack wrt rip]
	
	; Initialize the module linked list to null
	lea rax, [_Dmodule_ref wrt rip]
	mov qword [rax], 0	
    
    ; Put the loader data pointer into rdi (first argument)
	lea rax, [_loader_data wrt rip]
	mov [rax], rdi
	
	; Put table of interrupt serice routines into 2nd argument
	lea rsi, [_isrtable wrt rip]
	
	; Jump to D code
    call _startup
    
    jmp $

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data

_loader_data:
	dq 0

section .bss
    ; Reserve an 8K kernel stack
    resb 0x2000
    stack:
