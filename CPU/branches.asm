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
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
bne:
    mov eax, ebx ; copy instruction into eax and ecx
    mov ecx, ebx

    shr eax, 16 ; store rt into eax
    and eax, 0x1F
    mov eax, dword [processor + eax * 4]

    shr ecx, 21 ; store the index of rs in ecx
    and ecx, 0x1F

    cmp eax, dword [processor + ecx * 4] ; compare rs and rt
    jne branch ; if they're not equal, jump to the branch handler
    ret

; params:
; ebx -> instruction (bx = imm)
; not preserved -> ebx
branch:
    movsx ebx, bx ; sign extend imm to 32 bits
    shl ebx, 2 ; multiply by 4 (to enforce alignment)
    add dword [processor + pc], ebx ; add signed offset to pc
    sub dword [processor + pc], 4   ; I increment PC by 4 after every instruction, including branches. This just undoes that
                                    ; TODO: Optimize this out
    ret
%endif