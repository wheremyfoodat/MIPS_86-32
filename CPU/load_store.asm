%ifndef LOAD_STORE_ASM
%define LOAD_STORE_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"

section .data
    lui_msg: db "LUI $%d, %04X", 0xA, 0 ; For disassembly in the future

section .text

; params: 
; ebx -> instruction
; not preserved: eax
lui:
    mov eax, ebx ; copy instruction into eax
    sar eax, 16 ; fetch index of rt 
    and eax, 0x1F

    mov word [processor + eax * 4 + 2], bx ; move the immediate into the top 16 bits of the register
    jmp executeInstruction.exit

%endif