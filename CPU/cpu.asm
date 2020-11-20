%ifndef CPU_ASM
%define CPU_ASM

%include "include\cpu.inc"
%include "CPU\load_store.asm"
%include "CPU\alu.asm"

extern _exit

section .data
    unknown_opcode_msg: db "Unknown opcode %08X", 0xA, 0
    opcode_table: ; Jump table of opcodes
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 0-7
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, ori, unknown_op, lui ; 8-F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 10-17
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 18-1F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 20-27
        dd unknown_op, unknown_op, unknown_op, sw, unknown_op, unknown_op, unknown_op, unknown_op ; 28-2F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 30-37
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 38-3F

section .bss
    processor: resb MIPS_size

section .text

init_cpu:
    mov dword [processor + pc], 0xBFC00000 ; set PC to start of BIOS
    ret

; sets eax to the opcode and ebx to the instruction
; then jumps to the instruction handler
executeInstruction:
    mov dword [processor + GPRs], 0 ; set $zero to 0
    mov eax, dword [processor + pc] ; read 32 bits from mem[pc]
    call read32

    mov ebx, eax ; store instruction in ebx
    shr eax, 26 ; get opcode

    jmp [opcode_table + eax * 4] ; jump to instruction handler

.exit:    
    add dword [processor + pc], 4 ; inc PC by 4
    ret

unknown_op: ; unknown opcode handler
    push ebx ; print unknown instruction
    push unknown_opcode_msg 
    call _printf
    call _exit ; abort

%endif