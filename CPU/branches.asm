%ifndef BRANCHES_ASM
%define BRANCHES_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"

section .data
    j_msg: db "j %07X", 0xA, 0 ; For disassembly in the future

section .text

; params: 
; ebx -> instruction
; not preserved: ebx
j:
    and dword [processor + pc], 0xF0000000 ; pc = pc & 0xF000'0000
    and ebx, 0x3FFFFFF ; fetch 26-bit immediate
    shl ebx, 2 ; shift imm by 2
    or dword [processor + pc], ebx ; pc = pc | immediate
    jmp executeInstruction.exit
%endif