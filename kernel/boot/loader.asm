BITS 64

global _loader           ; making entry point visible to linker
extern _main
extern data

section .text
_loader:
    lea rsp, [stack wrt rip]
	lea rax, [_loader_data wrt rip]
	mov [rax], rdi

    call _main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .data

_loader_data:
	dq 0

section .bss
    ; Reserve an 8K kernel stack
    resb 0x2000
    stack:
