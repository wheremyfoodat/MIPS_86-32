%ifndef ALU_ASM
%define ALU_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"
extern _printf

section .data
    ori_msg: db "ORI $%d, %04X", 0xA, 0 ; For disassembly in the future
    debug_remove_later: db "$8 = %08X", 0xA, 0

    alu_opcode_table:
        dd sll, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 0-7
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 8-F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 10-17
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 18-1F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 20-27
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 28-2F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 30-37
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 38-3F


section .text

; params: 
; ebx -> instruction
; not preserved: eax
ori:
    mov eax, ebx ; copy instruction into eax
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F

    or word [processor + eax * 4], bx ; or low 12 bits of the register with imm
    jmp executeInstruction.exit

; params: 
; ebx -> instruction
; not preserved: eax
sll:
    mov eax, ebx
    mov ecx, ebx

    shr ebx, 16
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4] ; set ebx to rt

    shr eax, 11
    and eax, 0x1F ; set eax to rd index
    
    shr ecx, 6
    and ecx, 0x1F

    shl ebx, cl ; ebx = rt << h
    mov dword [processor + eax * 4], ebx ; rd = ecx
    jmp alu_op_type_r.exit

; There's multiple instructions with the opcode 0x00
; They're all type-R ALU instructions
; This function decodes such an instruction and executes it
; params: 
; ebx -> instruction
; not preserved: eax
alu_op_type_r:
    mov eax, ebx
    and eax, 0x1F ; fetch the instruction type
    jmp [alu_opcode_table + eax * 4] ; jump to the handler

.exit:
    jmp executeInstruction.exit
%endif