%include "CPU\cpu.asm"
%include "memory.asm"
%include "macros.asm"

bits 32
global _main

extern _printf     

section .data
fmt: db "This should be 0x3C080013 -> 0x%08X", 0xA, 0
filePermissions: db "r", 0

section .bss
    buffer resb 1024
    bufferSize: equ 1024

section .text
_main:
    call init_mem
    call init_cpu

    push dword[mem + BIOS] ; Print 4 bytes of it to see if we read the BIOS properly
    push fmt
    call _printf
    add esp, 8 ; clean up stack

.emulationLoop:
    call executeInstruction
    jmp .emulationLoop

    xor eax, eax ; return code
    ret 