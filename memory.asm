%include "include\memory.inc"
%include "macros.asm"

; TODO: Use a jump table for loads
; TODO: handle masking
extern _exit

section .data
    read32_unknown_msg: db "32 bit read from unimplemented address %08X", 0xA, 0
    write32_unknown_msg: db "32 bit write to unimplemented address %08X (value = %08X)", 0xA, 0

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

; params:
; eax -> 32-bit value to store
; ebx -> address to write to
write32:
    jmp write32_unknown


read32_BIOS:
    sub eax, 0xBFC00000 ; TODO: Use a mask instead
    mov eax, dword [mem + BIOS + eax]
    jmp read32.exit

read32_unknown:
    push eax ; print error message
    push read32_unknown_msg
    call _printf
    add esp, 8 ; clean up stack
    ; jmp read32.exit
    call _exit ; abort

write32_unknown:
    push eax
    push ebx
    push write32_unknown_msg
    call _printf

    add esp, 12 ; clean up stack
    ret