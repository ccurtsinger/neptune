global _loader                                      ; Linker entry location
extern _main                                        ; D entry point

; GRUB multiboot header data
MODULEALIGN equ  1<<0                               ; Align loaded modules on page boundaries
MEMINFO     equ  1<<1                               ; Provide memory map

FLAGS       equ  MODULEALIGN | MEMINFO              ; Multiboot flags
MAGIC       equ    0x1BADB002                       ; Magic number for locating multiboot header
CHECKSUM    equ -(MAGIC + FLAGS)                    ; Checksum of header data

KERNEL_VIRTUAL_BASE equ 0xC0000000                  ; 3GB
KERNEL_DIR_OFFSET equ (KERNEL_VIRTUAL_BASE >> 22)   ; Page directory index of kernel's 4MB PTE.
PAGE_DIR_ENTRY_BITS equ 0x203                       ; Set present, writable, and used bits
STACKSIZE equ 0x4000                                ; Reserve 16K for kernel startup stack

section .data

; L0 Page Directory
align 0x1000
pagedir:
    times 1024 dd 0

; L1 Page Directory for kernel memory (lower level mapping)
align 0x1000
kernel_pagetable_lower:
    %assign i 0
    %rep 1024
    dd PAGE_DIR_ENTRY_BITS | i
    %assign i i+0x1000
    %endrep
    
; L1 Page Directory for kernel memory (upper level mapping)
align 0x1000
kernel_pagetable_upper:
    %assign i 0
    %rep 1024
    dd PAGE_DIR_ENTRY_BITS | i
    %assign i i+0x1000
    %endrep

; L1 Page Directory for referencing user memory's L1 directories
align 0x1000
user_mem_dir:
    times 1024 dd 0

; L1 Page Directory for referencing kernel memory's L1 directories
align 0x1000
kernel_mem_dir:
    times 1024 dd 0

section .text
align 4
MultiBootHeader:
    dd MAGIC
    dd FLAGS
    dd CHECKSUM

_loader:
    mov ecx, (pagedir - KERNEL_VIRTUAL_BASE)
    mov cr3, ecx                                        ; Load Page Directory Base Register.

    ; Map the kernel in at 0
    mov edx, (kernel_pagetable_lower - KERNEL_VIRTUAL_BASE) ; Get physical address of the kernel pagetable
    or edx, PAGE_DIR_ENTRY_BITS                             ; Mark the present and writable bits for use as a page dir entry
    mov [ecx], edx                                          ; Put the entry in the first index
    
    ; Map the user_mem_dir in one L1 dir below the kernel
    mov esi, (user_mem_dir - KERNEL_VIRTUAL_BASE)           ; Get physical address of the user_mem_dir
    mov ebp, esi                                            ; Copy the physical address
    or ebp, PAGE_DIR_ENTRY_BITS                             ; Mark the present and writable bits for use as a page dir entry
    mov [ecx + (KERNEL_DIR_OFFSET-1)*4], ebp                ; Add the entry to the page directory
    
    ; Populate the user_mem_dir
    mov [esi], edx                                          ; Add an entry for the kernel_pagetable to the user_mem_dir
    mov [esi + (KERNEL_DIR_OFFSET-1)*4], ebp                ; Add an entry for the user_mem_dir to the user_mem_dir
    
    ; Map the kernel in at KERNEL_VIRTUAL_BASE
    mov edx, (kernel_pagetable_upper - KERNEL_VIRTUAL_BASE) ; Get physical address of the kernel pagetable
    or edx, PAGE_DIR_ENTRY_BITS                             ; Mark the present and writable bits for use as a page dir entry
    mov [ecx + KERNEL_DIR_OFFSET*4], edx                    ; Put the entry in the KERNEL_VIRTUAL_BASE index
    
    ; Map the kernel_mem_dir in at the highest L1 page dir
    mov esi, (kernel_mem_dir - KERNEL_VIRTUAL_BASE)         ; Get physical address of the kernel_mem_dir
    mov ebp, esi                                            ; Copy the physical address
    or ebp, PAGE_DIR_ENTRY_BITS                             ; Mark the present and writable bits for use as a page dir entry
    mov [ecx + 1023*4], ebp                                 ; Add the entry to the page directory
    
    ; Populate the kernel_mem_dir
    mov [esi + KERNEL_DIR_OFFSET*4], edx                    ; Add an entry for the kernel_pagetable to the kernel_mem_dir
    mov [esi + 1023*4], ebp                                 ; Add an entry for the kernel_mem_dir to the kernel_mem_dir

    ;mov ecx, cr4
    ;or ecx, 0x00000010                                     ; Set PSE bit in CR4 to enable 4MB pages.
    ;mov cr4, ecx

    mov ecx, cr0
    or ecx, 0x80000000                                      ; Set PG bit in CR0 to enable paging.
    mov cr0, ecx

    lea ecx, [higher_half]                                  ; Fetch an instruction in the higher half
    jmp ecx                                                 ; Jump to the upper-half

higher_half:

    mov ebp, 0
    mov esp, stack+STACKSIZE    ; Set up the stack
    
    push eax                    ; Pass Multiboot magic number
    push ebx                    ; Pass a pointer to the multiboot header

    call  _main                 ; Call kernel proper
    
    hlt                         ; Halt machine should kernel return
    jmp $                       ; Loop forever just in case interrupts are on

section .bss
align 32
stack:
    resb STACKSIZE

