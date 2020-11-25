; TODO: Use macros here
%ifndef ALU_ASM
%define ALU_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"
%include "CPU\exceptions.asm"
%include "macros.asm"
extern _exit

section .data
    ori_msg: db "ORI $%d, %04X", 0xA, 0 ; For disassembly in the future 

    alu_opcode_table:
        dd sll, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 0-7
        dd jr, jalr, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 8-F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 10-17
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 18-1F
        dd add, addu, unknown_op, unknown_op, and, or, unknown_op, unknown_op ; 20-27
        dd unknown_op, unknown_op, unknown_op, sltu, unknown_op, unknown_op, unknown_op, unknown_op ; 28-2F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 30-37
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 38-3F

section .text

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
or:
    mov eax, ebx ; copy instruction to eax and ecx
    mov ecx, ebx

    shr ebx, 21 ; set ebx to rs index
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4] ; set ebx to rs

    shr ecx, 16 ; set ecx to rt index
    and ecx, 0x1F
    or ebx, dword [processor + ecx * 4] ; ebx |= rt

    shr eax, 11
    and eax, 0x1F ; set eax to rd index

    mov dword [processor + eax * 4], ebx ; rd = ebx
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
and:
    mov eax, ebx ; copy instruction to eax and ecx
    mov ecx, ebx

    shr ebx, 21 ; set ebx to rs index
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4] ; set ebx to rs

    shr ecx, 16 ; set ecx to rt index
    and ecx, 0x1F
    and ebx, dword [processor + ecx * 4] ; ebx &= ecx

    shr eax, 11
    and eax, 0x1F ; set eax to rd index

    mov dword [processor + eax * 4], ebx ; rd = ebx
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
sltu:
    mov eax, ebx ; copy instruction to eax and ecx
    mov ecx, ebx

    shr ebx, 21 ; set ebx to rs index
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4] ; set ebx to rs

    shr ecx, 16 ; set ecx to rt index
    and ecx, 0x1F
    
    cmp ebx, dword [processor + ecx * 4] ; check if rs < rt
    setb bl ; set ebx to 1 if rs < rt
    movzx ebx, bl 

    shr eax, 11
    and eax, 0x1F ; set eax to rd index

    mov dword [processor + eax * 4], ebx ; rd = ebx
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
ori:
    mov eax, ebx ; copy instruction into eax
    mov ecx, ebx ; copy instruction into ecx

    shr ecx, 21 ; fetch index of rs
    and ecx, 0x1F
    
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F

    and ebx, 0xFFFF ; zero out top bits of ebx
    or ebx, dword [processor + ecx * 4]; imm |= rs

    mov dword [processor + eax * 4], ebx ; rt = imm
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
andi:
    mov eax, ebx ; copy instruction into eax
    mov ecx, ebx ; copy instruction into ecx

    shr ecx, 21 ; fetch index of rs
    and ecx, 0x1F
    
    shr eax, 16 ; fetch index of rt 
    and eax, 0x1F

    and ebx, 0xFFFF ; zero out top bits of ebx
    and ebx, dword [processor + ecx * 4]; imm &= rs

    mov dword [processor + eax * 4], ebx ; rt = imm
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
addu:
    mov eax, ebx ; copy instruction to eax and ecx
    mov ecx, ebx

    shr ebx, 21 ; set ebx to rs index
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4] ; set ebx to rs

    shr ecx, 16 ; set ecx to rt index
    and ecx, 0x1F
    add ebx, dword [processor + ecx * 4] ; ebx = rs + rt

    shr eax, 11
    and eax, 0x1F ; set eax to rd index

    mov dword [processor + eax * 4], ebx ; rd = ebx
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
add:
    mov eax, ebx ; copy instruction to eax and ecx
    mov ecx, ebx

    shr ebx, 21 ; set ebx to rs index
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4] ; set ebx to rs

    shr eax, 11
    and eax, 0x1F ; set eax to rd index

    shr ecx, 16 ; set ecx to rt index
    and ecx, 0x1F
    add ebx, dword [processor + ecx * 4] ; ebx = rs + rt

    mov dword [processor + eax * 4], ebx ; rd = ebx
    jo throwException ; if an exception occured, throw it
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
addiu:
    mov eax, ebx ; copy instruction into eax and ecx
    mov ecx, ebx 

    shr eax, 16 ; store index of rt into eax
    and eax, 0x1F

    shr ecx, 21 ; store index of rs into ecx
    and ecx, 0x1F

    movsx ebx, bx ; sign extend 16-bit imm in ebx
    add ebx, dword [processor + ecx * 4] ; add rs to ebx
    mov dword [processor + eax * 4], ebx ; store result in rt
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
addi:
    mov eax, ebx ; copy instruction into eax and ecx
    mov ecx, ebx 

    shr eax, 16 ; store index of rt into eax
    and eax, 0x1F

    shr ecx, 21 ; store index of rs into ecx
    and ecx, 0x1F

    movsx ebx, bx ; sign extend 16-bit imm in ebx
    add ebx, dword [processor + ecx * 4] ; add rs to ebx
    mov dword [processor + eax * 4], ebx ; store result in rt

    jo throwException ; if yes, jump to overflow handler
    ret ; return

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx
sll:
    mov eax, ebx ; copy instruction to eax and ecx
    mov ecx, ebx

    shr ebx, 16
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4] ; set ebx to rt

    shr eax, 11
    and eax, 0x1F ; set eax to rd index
    
    shr ecx, 6 ; get shift offset
    and ecx, 0x1F

    shl ebx, cl ; ebx = rt << h
    mov dword [processor + eax * 4], ebx ; rd = ecx
    ret ; return

; There's multiple instructions with the opcode 0x00
; They're all type-R ALU instructions
; This function decodes such an instruction and executes it
; params: 
; ebx -> instruction
; not preserved: eax
alu_op_type_r:
    mov eax, ebx
    and eax, 0x3F ; fetch the instruction type
    jmp [alu_opcode_table + eax * 4] ; jump to the handler
%endif