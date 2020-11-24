%include "include\memory.inc"
%include "macros.asm"

; TODO: handle mirroring
; TODO: Optimize range checking
; TODO: Use macros for functions instead of huge handwritten subroutines
; TODO: Bake the memory read/write subroutines inside of read/write 8/16/32 instead of having them be separate? (-1 JMP per access)
extern _exit

section .data
    read8_unknown_msg:  db "8-bit read from unimplemented address %08X", 0xA, 0
    read32_unknown_msg: db "32 bit read from unimplemented address %08X", 0xA, 0
    write8_unknown_msg: db "8 bit write to unimplemented address %08X (value = %02X)", 0xA, 0
    write16_unknown_msg: db "16 bit write to unimplemented address %08X (value = %04X)", 0xA, 0
    write32_unknown_msg: db "32 bit write to unimplemented address %08X (value = %08X)", 0xA, 0

region_masks: ; for handling KUSEG/KSEG0/KSEG1/KSEG2
    dd 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF ; KUSEG (2048MB)
    dd 0x7FFFFFFF                                     ; KSEG0 (512 MB)
    dd 0x1FFFFFFF                                     ; KSEG1 (512 MB)
    dd 0xFFFFFFFF, 0xFFFFFFFF                         ; KSEG2 (1024 MB)


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
; corrupted: esi
read8:
    mov esi, eax ; move address to esi
    shr esi, 29 ; apply the region mask to addr
    mov esi, dword [region_masks + esi * 4]
    and eax, esi ; AND address with region mask

.checkIfWRAM: ; check eax < 0x1FFFFF
    cmp eax, 0x1FFFFF
    ja .checkIfExpansion1 ; if > 0x1FFFFF, check if it belongs in Expansion 1
    jmp read8_WRAM

.checkIfExpansion1:
    cmp eax, 0x1F000000 ; if addr < 0x1F000000 throw error
    jb read8_unknown
    cmp eax, 0x1F7FFFFF ; if addr > 0x1F7FFFF, check if BIOS
    ja .checkIfBIOS
    mov eax, 0xFF ; If addr is in expansion 1, return 0xFF
    ret 

.checkIfBIOS:
    cmp eax, 0x1FC00000 ; check if 0x1FC00000 <= eax <= 0x17C7FFFF
    jb read8_unknown   ; if so, jump to unknown read handler
    cmp eax, 0x1FC7FFFF
    ja read8_unknown
    jmp read8_BIOS

; params: 
; eax -> address to read word from
; returns:
; eax -> word at that address
; corrupted: esi
read32:
    mov esi, eax ; move address to esi
    shr esi, 29 ; apply the region mask to addr
    mov esi, dword [region_masks + esi * 4]
    and eax, esi ; AND address with region mask

.checkIfWRAM: ; check eax < 0x1FFFFF
    cmp eax, 0x1FFFFF
    ja .checkIfExpansion1 ; if > 0x1FFFFF, check if it belongs in the BIOS
    jmp read32_WRAM

.checkIfExpansion1:
    cmp eax, 0x1F000000 ; if addr < 0x1F000000 throw error
    jb read8_unknown
    cmp eax, 0x1F7FFFFF ; if addr > 0x1F7FFFF, check if BIOS
    ja .checkIfBIOS
    mov eax, 0xFFFFFFFF ; If addr is in expansion 1, return 0xFF
    ret 

.checkIfBIOS:
    cmp eax, 0x1FC00000 ; check if 0x1FC00000 <= eax <= 0x17C7FFFF
    jb read32_unknown   ; if so, jump to unknown read handler
    cmp eax, 0x1FC7FFFF
    ja read32_unknown
    jmp read32_BIOS

; params:
; eax -> 8-bit value to store
; ebx -> address to write to
; corrupted: esi
write8:
    mov esi, ebx ; move address to esi
    shr esi, 29 ; apply the region mask to addr
    mov esi, dword [region_masks + esi * 4]
    and ebx, esi ; AND address with region mask
    
    cmp ebx, 0x1FFFFF ; if addr >= 0x200000, jump to unknown write handler
    ja write8_unknown
    jmp write8_WRAM

; params:
; eax -> 16-bit value to store
; ebx -> address to write to
; corrupted: esi
write16:
    mov esi, ebx ; move address to esi
    shr esi, 29 ; apply the region mask to addr
    mov esi, dword [region_masks + esi * 4]
    and ebx, esi ; AND address with region mask
    
    cmp ebx, 0x1FFFFF ; if addr >= 0x200000, jump to unknown write handler
    ja write16_unknown
    jmp write16_WRAM

; params:
; eax -> 32-bit value to store
; ebx -> address to write to
; corrupted: esi
write32:
    mov esi, ebx ; move address to esi
    shr esi, 29 ; apply the region mask to addr
    mov esi, dword [region_masks + esi * 4]
    and ebx, esi ; AND address with region mask
    
    cmp ebx, 0x1FFFFF ; if addr >= 0x200000, jump to unknown write handler
    ja write32_unknown
    jmp write32_WRAM

read8_WRAM:
    and eax, 0x001FFFFF ; TODO: Handle WRAM size regs
    mov al, byte [mem + WRAM + eax] ; TODO: handle mirroring properly
    movzx eax, al ; zero extend the value into eax
    ret

read32_WRAM:
    and eax, 0x001FFFFF ; TODO: Handle WRAM size regs
    mov eax, dword [mem + WRAM + eax] ; TODO: handle mirroring properly
    ret

write8_WRAM:
    and ebx, 0x001FFFFF ; TODO: Handle WRAM size regs
    mov byte [mem + WRAM + ebx], al
    ret

write16_WRAM:
    and ebx, 0x001FFFFF ; TODO: Handle WRAM size regs
    mov word [mem + WRAM + ebx], ax
    ret

write32_WRAM:
    and ebx, 0x001FFFFF ; TODO: Handle WRAM size regs
    mov dword [mem + WRAM + ebx], eax
    ret

read8_BIOS:
    sub eax, 0x1FC00000 ; TODO: Use a mask instead (?)
    mov al, byte [mem + BIOS + eax]
    movzx eax, al ; zero extend loaded value into eax
    ret

read32_BIOS:
    sub eax, 0x1FC00000 ; TODO: Use a mask instead (?)
    mov eax, dword [mem + BIOS + eax]
    ret

read8_unknown:
    printMIPSRegs
    push eax ; print error message
    push read8_unknown_msg
    call _printf
    add esp, 8 ; clean up stack
    call _exit

read32_unknown:    
    printMIPSRegs
    push eax ; print error message
    push read32_unknown_msg
    call _printf
    add esp, 8 ; clean up stack
    ; ret
    call _exit ; abort

write8_unknown:
    push eax
    push ebx
    push write8_unknown_msg
    call _printf

    add esp, 12
    ret

write16_unknown:
    push eax
    push ebx
    push write16_unknown_msg
    call _printf

    add esp, 12
    ret

write32_unknown:
    push eax
    push ebx
    push write32_unknown_msg
    call _printf

    add esp, 12
    ret