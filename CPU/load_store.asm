; TODO: Use macros here

%ifndef LOAD_STORE_ASM
%define LOAD_STORE_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"

section .data
    lui_msg: db "LUI $%d, %04X", 0xA, 0 ; For disassembly in the future
    cache_isolation_msg: db "[Bus][Warning] Tried to access memory while cache isolated", 0xA, 0

section .text

cacheIsolationError: ; happens when the CPU accesses main memory with cache isolated
    push cache_isolation_msg 
    call _printf
    add esp, 4
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
lui:
    mov eax, ebx ; copy instruction into eax
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F
    shl ebx, 16 ; shift 16-bit immediate to the left

    mov dword [processor + eax * 4], ebx ; move the immediate into the top 16 bits of the register
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
sw:
    test dword [processor + cop0 + sr], 0x10000 ; check cache isolation bit
    jnz cacheIsolationError

    mov eax, ebx ; copy instruction into eax
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F
    mov eax, dword [processor + eax * 4] ; fetch rt

    mov ecx, ebx ; copy instruction into ecx
    shr ecx, 21 ; fetch index of rs
    and ecx, 0x1F

    movsx ebx, bx ; sign extend the 16-bit immediate to 32 bits
    add ebx, dword [processor + ecx * 4]
    call write32 ; store rt at (rs + offset)

    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
sh:
    test dword [processor + cop0 + sr], 0x10000 ; check cache isolation bit
    jnz cacheIsolationError

    mov eax, ebx ; copy instruction into eax
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F
    mov eax, dword [processor + eax * 4] ; fetch rt

    mov ecx, ebx ; copy instruction into ecx
    shr ecx, 21 ; fetch index of rs
    and ecx, 0x1F

    movsx ebx, bx ; sign extend the 16-bit immediate to 32 bits
    add ebx, dword [processor + ecx * 4]
    call write16 ; store rt at (rs + offset)
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
sb:
    test dword [processor + cop0 + sr], 0x10000 ; check cache isolation bit
    jnz cacheIsolationError

    mov eax, ebx ; copy instruction into eax
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F
    mov eax, dword [processor + eax * 4] ; fetch rt

    mov ecx, ebx ; copy instruction into ecx
    shr ecx, 21 ; fetch index of rs
    and ecx, 0x1F

    movsx ebx, bx ; sign extend the 16-bit immediate to 32 bits
    add ebx, dword [processor + ecx * 4]
    call write8 ; store rt at (rs + offset)
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
lb:
    test dword [processor + cop0 + sr], 0x10000 ; check cache isolation bit
    jnz cacheIsolationError

    mov eax, ebx ; copy instruction into eax, ecx
    mov ecx, ebx 

    shr ecx, 16 ; fetch index of rt 
    and ecx, 0x1F

    shr eax, 21 ; fetch index of rs
    and eax, 0x1F
    mov eax, dword [processor + eax * 4] ; fetch rs

    movsx ebx, bx ; sign extend the 16-bit immediate to 32 bits
    add eax, ebx
    call read8 ; load byte from (rs + offset) into eax
    movsx eax, al ; sign extend 8-bit value to 32-bits
    mov dword [processor + ecx * 4], eax ; store it into rt
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
lbu: ; literally LB without sign extension
    test dword [processor + cop0 + sr], 0x10000 ; check cache isolation bit
    jnz cacheIsolationError

    mov eax, ebx ; copy instruction into eax, ecx
    mov ecx, ebx 

    shr ecx, 16 ; fetch index of rt 
    and ecx, 0x1F

    shr eax, 21 ; fetch index of rs
    and eax, 0x1F
    mov eax, dword [processor + eax * 4] ; fetch rs

    movsx ebx, bx ; sign extend the 16-bit immediate to 32 bits
    add eax, ebx
    call read8 ; load byte from (rs + offset) into eax
    mov dword [processor + ecx * 4], eax ; store it into rt
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
lw:
    test dword [processor + cop0 + sr], 0x10000 ; check cache isolation bit
    jnz cacheIsolationError

    mov eax, ebx ; copy instruction into eax, ecx
    mov ecx, ebx 

    shr ecx, 16 ; fetch index of rt 
    and ecx, 0x1F

    shr eax, 21 ; fetch index of rs
    and eax, 0x1F
    mov eax, dword [processor + eax * 4] ; fetch rs

    movsx ebx, bx ; sign extend the 16-bit immediate to 32 bits
    add eax, ebx
    call read32 ; load word from (rs + offset) into eax
    mov dword [processor + ecx * 4], eax ; store it into rt
    ret

%endif