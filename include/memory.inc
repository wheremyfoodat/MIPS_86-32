KILOBYTE: equ 1024

section .data
BIOSDirectory: db "ROMs\BIOS.bin", 0

section .bss
struc memory
    BIOS: resb 512 * KILOBYTE
    WRAM: resb 2048 * KILOBYTE
endstruc
