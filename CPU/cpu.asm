%ifndef CPU_ASM
%define CPU_ASM

%include "include\cpu.inc"
%include "CPU\load_store.asm"
%include "CPU\alu.asm"
%include "CPU\branches.asm"
%include "CPU\coprocessors\coprocessor.asm"

extern _printf
extern _exit

section .data
    unknown_opcode_msg: db "Unknown instruction %08X Opcode %02X", 0xA, 0
    exception_error_msg: db "Attempted to throw exception!", 0xA, 0
    opcode_table: ; Jump table of opcodes
        dd alu_op_type_r, bxx, j, jal, beq, bne, blez, bgtz ; 0-7
        dd addi, addiu, slti, sltiu, andi, ori, unknown_op, lui ; 8-F
        dd cop0_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 10-17
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 18-1F
        dd lb, unknown_op, unknown_op, lw, lbu, unknown_op, unknown_op, unknown_op ; 20-27
        dd sb, sh, unknown_op, sw, unknown_op, unknown_op, unknown_op, unknown_op ; 28-2F
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 30-37
        dd unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op, unknown_op ; 38-3F
    print_char_msg: db "%c", 0

section .bss
    processor: resb MIPS_size

section .text

init_cpu:
    mov dword [processor + pc], 0xBFC00000 ; set PC to start of BIOS
    mov dword [processor + nextInstruction], 0 ; Opcode for sll $0, $0, 0, the most common encoding for NOP in MIPS
    ret

; sets eax to the opcode and ebx to the instruction
; then jumps to the instruction handler
executeInstruction:
    mov dword [processor + GPRs], 0 ; set $zero to 0
    mov ebx, dword [processor + nextInstruction] ; read the instruction to be executed into ebx
    mov eax, dword [processor + pc] ; read 32 bits from mem[pc]
    call read32
    mov dword [processor + nextInstruction], eax ; set eax as the instruction to be executed in the next cycle
    add dword [processor + pc], 4 ; inc PC by 4

    mov eax, ebx ; copy instruction to eax
    shr eax, 26 ; get opcode

    ;cmp dword [processor + pc], 0xB0 <- For BIOS logging purposes. Ignore this
    ;jne exit
    ;cmp dword [processor + 9 * 4], 0x3D
    ;jne exit

    ;pusha
    ;push dword [processor + 4 * 4]
    ;push dword print_char_msg
    ;call _printf
    ;add esp, 8
    ;popa

exit:
    jmp [opcode_table + eax * 4] ; jump to instruction handler

unknown_op: ; unknown opcode handler
    printMIPSRegs
    mov eax, ebx ; fetch opcode
    shr eax, 26
    push eax ; print opcode of instruction
    push ebx ; print unknown instruction
    push unknown_opcode_msg
    call _printf ; print message
    call _exit ; abort

throw_exception:
    push exception_error_msg ; print an error msg
    call _printf 
    add esp, 4 ; clean up stack
    call _exit ; abort

%endif