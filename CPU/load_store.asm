%ifndef LOAD_STORE_ASM
%define LOAD_STORE_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"

section .data
    lui_msg: db "LUI $%d, %04X", 0xA, 0 ; For disassembly in the future

section .text

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
lui:
    mov eax, ebx ; copy instruction into eax
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F

    mov word [processor + eax * 4 + 2], bx ; move the immediate into the top 16 bits of the register
    jmp executeInstruction.exit

sw:
    mov eax, ebx ; copy instruction into eax
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F
    mov eax, dword [processor + eax * 4] ; fetch rt

    mov ecx, ebx ; copy instruction into ecx
    shr ecx, 21 ; fetch index of rs
    and ecx, 0x1F
    mov ecx, dword [processor + ecx * 4] ; fetch rs

    movsx ebx, bx ; sign extend the 16-bit immediate to 32 bits
    add ebx, ecx
    call write32 ; store rt at (rs + offset)

    jmp executeInstruction.exit
%endif