%ifndef COPROCESSOR_ASM
%define COPROCESSOR_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"
extern _printf
extern _exit

section .data
    cop_read_msg: db "Tried to read to r%d from cop%d (register = %d)", 0xA, 0
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
    test eax, eax ; check if mfc0
    je mfc0
    jmp cop_unknown_op ; if neither, throw an error

mtc0:
    mov eax, ebx ; copy instruction into eax
    shr eax, 11  ; get coprocessor register to write to (rd)
    and eax, 0x1F

    shr ebx, 16 ; get rt index
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4]
    
    mov dword [processor + cop0 + eax * 4], ebx

    push eax ; print a warning
    push 0
    push dword [processor + ebx * 4]
    push cop_write_msg
    call _printf
    add esp, 16 ; clean up stack

    ret

mfc0:
    mov eax, ebx ; copy instruction into eax
    shr eax, 11  ; get coprocessor register to read from
    and eax, 0x1F
    mov eax, dword [processor + cop0 + eax * 4]

    shr ebx, 16 ; get rt index
    and ebx, 0x1F
    mov dword [processor + ebx * 4], eax

    push eax ; print a warning
    push 0
    push ebx 
    push cop_read_msg
    call _printf
    add esp, 16 ; clean up stack
    
    ret

cop_unknown_op:
    printMIPSRegs
    shr ebx, 26 
    and ebx, 3 ; fetch cop number
    push ebx   ; push cop number
    push eax   ; push operation number
    push cop_unknown_op_msg ; print unknown coprocessor operation msg
    call _printf
    add esp, 12 ; clean up stack
    call _exit ; abort
%endif