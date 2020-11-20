%include "include\memory.inc"
%include "macros.asm"

; TODO: Use a jump table for loads
; TODO: handle masking

section .data
    read32_unknown_msg: db "32 bit read from unimplemented address %08X", 0xA, 0

section .bss
    mem: resb memory_size

section .text
    
init_mem:
    readFileIntoBuffer BIOSDirectory, filePermissions, BIOSSize, 1, mem + BIOS
    ret

; params: 
; eax -> address to read word from
; returns:
; eax -> word at that address
read32:
    cmp eax, 0xBFC00000
    jae read32_BIOS
    jmp read32_unknown

.exit:
    ret

read32_BIOS:
    sub eax, 0xBFC00000 ; TODO: Use a mask instead
    mov eax, dword [mem + BIOS + eax]
    jmp read32.exit

read32_unknown:
    push eax ; print error message
    push read32_unknown_msg
    call _printf
    add esp, 8
    jmp read32.exit