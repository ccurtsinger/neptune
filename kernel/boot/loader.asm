BITS 64

global _loader           ; making entry point visible to linker
extern _startup;, _exit
extern start_ctors, end_ctors
extern _Dmodule_ref
extern _isrtable

section .text
_loader:
	; Initialize the stack pointer
    lea rsp, [stack wrt rip]
	
	; Initialize the module linked list to null
	lea rax, [_Dmodule_ref wrt rip]
	mov qword [rax], 0
	
	; Call all module constructors
    static_ctors_loop:
		lea rbx, [start_ctors wrt rip]
   	    jmp .test
   	.body:
   	    call [rbx]
   	    add rbx,8
   	.test:
		lea rcx, [end_ctors wrt rip]
   	    cmp rbx, rcx
   	    jl .body 	
    
    ; Put the loader data pointer into rdi (first argument)
	lea rax, [_loader_data wrt rip]
	mov [rax], rdi
	
	; Put table of interrupt serice routines into 2nd argument
	lea rsi, [_isrtable wrt rip]
	
	; Jump to D code
    call _startup
    
    ;call _exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data

_loader_data:
	dq 0

section .bss
    ; Reserve a 16K kernel stack
    resb 0x4000
    stack:
