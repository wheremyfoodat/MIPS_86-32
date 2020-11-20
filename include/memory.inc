BIOSSize: equ 512 * 1024

section .data
BIOSDirectory: db "ROMs\BIOS.bin", 0

section .bss
struc memory
    BIOS: resb BIOSSize
endstruc
