%include "CPU\cpu.asm"
%include "memory.asm"
%include "macros.asm"

bits 32
global _main

extern _printf     

section .data
filePermissions: db "r", 0

section .text
_main:
    sub esp, 2048

    call init_mem
    call init_cpu

.emulationLoop:
    call executeInstruction
    jmp .emulationLoop

    add esp, 2048
    xor eax, eax ; return code
    ret 