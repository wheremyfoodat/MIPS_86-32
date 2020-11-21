%ifndef COPROCESSOR_ASM
%define COPROCESSOR_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"
extern _printf
extern _exit

section .data
    cop_read_msg: db "Unhandled read from cop%d (register = %d)", 0xA, 0
    cop_write_msg: db "Tried to write %08X to cop%d (register = %d)", 0xA, 0
    cop_unknown_op_msg: db "Unknown coprocessor operation %x to cop%d", 0xA, 0

section .text
; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
cop0_op:
    mov eax, ebx ; copy instruction into ebx
    shr eax, 21 ; fetch the coprocessor operation type
    and eax, 0x1F

    cmp eax, 4 ; check if mtc0
    je mtc0
    jmp cop_unknown_op

mtc0:
    mov eax, ebx ; copy instruction into eax
    shr eax, 11  ; get coprocessor register # to write to (rd)
    and eax, 0x1F

    shr ebx, 16 ; get rt index
    and eax, 0x1F

    push eax ; print a warning
    push 0
    push dword [processor + eax * 4]
    push cop_write_msg
    call _printf
    add esp, 16 ; clean up stack

    jmp executeInstruction.exit

cop_unknown_op:
    shr ebx, 26
    push ebx
    push eax
    push cop_unknown_op_msg ; print unknown coprocessor operation msg
    call _printf
    add esp, 12 ; clean up stack
    call _exit ; abort
%endif