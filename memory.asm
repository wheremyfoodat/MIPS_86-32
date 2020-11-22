%include "include\memory.inc"
%include "macros.asm"

; TODO: Use a jump table for loads
; TODO: handle masking
; TODO: Optimize range checking
; TODO: Handle KUSEG/KSEG0/KSEG1 in a way that makes sense
extern _exit

section .data
    read32_unknown_msg: db "32 bit read from unimplemented address %08X", 0xA, 0
    write32_unknown_msg: db "32 bit write to unimplemented address %08X (value = %08X)", 0xA, 0

section .bss
    mem: resb memory_size

section .text
    
init_mem:
    readFileIntoBuffer BIOSDirectory, filePermissions, 512 * KILOBYTE, 1, mem + BIOS
    ret

; params: 
; eax -> address to read word from
; returns:
; eax -> word at that address
read32:
.checkIfWRAM: ; check eax >= 0xA000_0000 && eax <= 0xA01F_FFFF
    cmp eax, 0xA0000000 
    jb read32_unknown ; if < 0xA000_0000, print error
    cmp eax, 0xA01FFFFF
    ja .checkIfBIOS ; if > 0xA01FFFFF, check if it belongs in the BIOS
    jmp read32_WRAM

.checkIfBIOS:
    cmp eax, 0xBFC00000
    jae read32_BIOS
    jmp read32_unknown

; params:
; eax -> 32-bit value to store
; ebx -> address to write to
write32:
.checkIfKUSEGWRAM:
    cmp ebx, 0x001FFFFF
    ja .checkIfKSEG1WRAM
    jmp write32_WRAM

.checkIfKSEG1WRAM:
    cmp ebx, 0xA0000000 ; if < 0xA000_0000, print error
    jb write32_unknown
    cmp ebx, 0xA01FFFFF ; if > 0xA01FFFFF, print error
    ja write32_unknown

    jmp write32_WRAM


read32_WRAM:
    and ebx, 0x001FFFFF ; TODO: Handle WRAM size regs
    mov eax, dword [mem + WRAM + ebx] ; TODO: handle mirroring
    ret

write32_WRAM:
    and ebx, 0x001FFFFF ; TODO: Handle WRAM size regs
    mov dword [mem + WRAM + ebx], eax
    ret

read32_BIOS:
    sub eax, 0xBFC00000 ; TODO: Use a mask instead
    mov eax, dword [mem + BIOS + eax]
    ret

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