; TODO: Use macros here
%ifndef BRANCHES_ASM
%define BRANCHES_ASM

%include "include\cpu.inc"
%include "CPU\cpu.asm"

section .data
    j_msg: db "j %07X", 0xA, 0 ; For disassembly in the future
    branch_in_delay_slot_msg: db "Encountered a branch in a branch delay slot! Aborting!", 0xA, 0

section .text

; params: 
; ebx -> instruction
; not preserved: ebx
j:
    call check_if_branch_in_delay_slot
    and dword [processor + pc], 0xF0000000 ; pc = pc & 0xF000'0000
    and ebx, 0x3FFFFFF ; fetch 26-bit immediate
    shl ebx, 2 ; shift imm by 2
    or dword [processor + pc], ebx ; pc = pc | immediate
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx
jal:
    call check_if_branch_in_delay_slot
    mov eax, dword [processor + pc] ; store ret address in $ra
    mov dword [processor + $ra], eax

    and dword [processor + pc], 0xF0000000 ; pc = pc & 0xF000'0000
    and ebx, 0x3FFFFFF ; fetch 26-bit immediate
    shl ebx, 2 ; shift imm by 2
    or dword [processor + pc], ebx ; pc |= immediate
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx
jalr:
    call check_if_branch_in_delay_slot
    mov ecx, ebx ; copy instruction in ecx
    shr ecx, 11 ; get rd index
    and ecx, 0x1F
    
    shr ebx, 21 ; get rs
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4]

    mov eax, dword [processor + pc] ; fetch ret address
    mov dword [processor + ecx * 4], eax ; store ret address in rd

    mov dword [processor + pc], ebx ; store rs in PC
    ret

; params: 
; ebx -> instruction
; not preserved: ebx
jr:
    call check_if_branch_in_delay_slot
    shr ebx, 21 ; fetch rs index
    and ebx, 0x1F
    mov ebx, dword [processor + ebx * 4] ; fetch rs 

    mov dword [processor + pc], ebx ; store it in PC
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
; ebx -> instruction
; not preserved: eax, ebx, ecx
beq:
    mov eax, ebx ; copy instruction into eax and ecx
    mov ecx, ebx

    shr eax, 16 ; store rt into eax
    and eax, 0x1F
    mov eax, dword [processor + eax * 4]

    shr ecx, 21 ; store the index of rs in ecx
    and ecx, 0x1F

    cmp eax, dword [processor + ecx * 4] ; compare rs and rt
    je branch ; if they're not equal, jump to the branch handler
    ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx
bgtz:
    mov eax, ebx ; copy instruction into eax
    shr eax, 21 ; get rs index
    and eax, 0x3F
    cmp dword [processor + eax * 4], 0 ; check if rs > 0 (signed)
    jg branch ; if it is, branch
    ret ; if it is not, ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx
blez:
    mov eax, ebx ; copy instruction into eax
    shr eax, 21 ; get rs index
    and eax, 0x3F
    cmp dword [processor + eax * 4], 0 ; check if rs is <= 0 (signed)
    jle branch ; if it is 0, branch
    ret ; if it is not, ret

; params: 
; ebx -> instruction
; not preserved: eax, ebx, ecx, edx
bxx: ; BLTZ/BLTZAL/BGEZ/BGEZAL
    mov eax, ebx ; copy instruction to eax and ecx
    mov ecx, ebx 

    shr ecx, 21 ; get rs
    and ecx, 0x3F
    mov ecx, dword [processor + ecx * 4]

    shr eax, 17 ; see if should link
    and eax, 0xF
    cmp eax, 8
    je .link

.branch:
    test ebx, 0x10000
    jnz bgez ; if bit 16 is true, execute BGEZ
    jmp bltz ; else execute BLTZ

.link:
    mov edx, dword [processor + pc] ; get ret addr
    mov [processor + $ra], edx ; store in $ra
    jmp .branch ; return

bgez: ; rs is in ecx (thanks to the bxx function)
    cmp ecx, 0
    jge branch ; if >= 0, branch
    ret ; else ret

bltz: ; rs is in ecx (thanks to the bxx function)
    cmp ecx, 0
    jl branch ; if < 0, branch
    ret

; params:
; ebx -> instruction (bx = imm)
; not preserved -> ebx
branch:
    call check_if_branch_in_delay_slot
    movsx ebx, bx ; sign extend imm to 32 bits
    shl ebx, 2 ; multiply by 4 (to enforce alignment)
    add dword [processor + pc], ebx ; add signed offset to pc
    sub dword [processor + pc], 4   ; I increment PC by 4 after every instruction, including branches. This just undoes that
                                    ; TODO: Optimize this out
    ret

check_if_branch_in_delay_slot: ; TODO: Remove this and properly implement branches in d-slots
    push ecx
    push edx

    mov edx, dword [processor + nextInstruction] ; fetch delay slot instruction
    mov ecx, edx

    shr edx, 26 ; get opcode
    
    cmp edx, 2
    jb .part_2_electric_boogaloo
    cmp edx, 7
    ja .part_2_electric_boogaloo
    jmp branch_in_delay_slot 

.part_2_electric_boogaloo:
    cmp edx, 0 ; check if it's one of the jumps with opcode == 0
    jne .exit

    and ecx, 0x3F 
    cmp ecx, 0x8 ; check if JR
    jz branch_in_delay_slot
    cmp ecx, 0x9 ; check if JALR
    jz branch_in_delay_slot

.exit: 
    pop edx
    pop ecx
    ret

branch_in_delay_slot: ; if there's a branch in a branch delay slot, panic
    push branch_in_delay_slot_msg
    call _printf
    add esp, 4
    call _exit
%endif