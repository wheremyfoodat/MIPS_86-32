%ifndef ALU_ASM
%define ALU_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"
extern _printf

section .data
    ori_msg: db "ORI $%d, %04X", 0xA, 0 ; For disassembly in the future
    debug_remove_later: db "$8 = %08X", 0xA, 0

section .text

; params: 
; ebx -> instruction
; not preserved: eax
ori:
    mov eax, ebx ; copy instruction into eax
    sar eax, 16 ; fetch index of rt 
    and eax, 0x1F

    or word [processor + eax * 4], bx ; or low 12 bits of the register with imm
    jmp executeInstruction.exit

%endif