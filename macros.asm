%ifndef MACROS_ASM
%define MACROS_ASM

extern _printf
extern _fopen
extern _fread

section .bss:
fileReadFailMsg: db "Failed to read file %s :(", 0xA, 0
fileReadSuccessMsg: db "Successfully opened file %s! :)", 0xA, 0
printRegsFmt: db "eax: %08X, ebx: %08X", 0xA, "ecx: %08X, edx: %08X", 0xA, "esi: %08X, edi: %08X", 0xA, "ebp: %08X, esp: %08X", 0xA, 0

section .text:
; fopens a file, and freads its contents into a buffer
; params: 
; 1 -> fileName
; 2 -> filePermissions
; 3 -> number of elements
; 4 -> size of elements
; 5 -> pointer to buffer
%macro readFileIntoBuffer 5
    push %2
    push %1
    call _fopen ; fopen(filePermissions, fileName)
    
    add esp, 8   ; clean up stack
    mov ebx, eax ; store file descriptor in ebx
    mov eax, %1
    call checkReadFail ; check if file opened successfully

    push ebx ; push file descriptor
    push %3  ; element count
    push %4  ; size of element
    push %5  ; pointer to buffer
    call _fread ; fread (int* ptr, size_t size, size_t nmemb, FILE* stream)
    add esp, 16 ; clean up stack
%endmacro

; params:
; eax -> file name
; ebx -> file descriptor
checkReadFail:
    push eax ; push file name as param to printf
    test ebx, ebx ; check if ebx is null
    jz readFail
    push fileReadSuccessMsg
    call _printf
    add esp, 8 ; clean up stack
    ret

readFail:
    push fileReadFailMsg
    call _printf
    add esp, 8 ; clean up stack
    ret

; prints the most important host regs
%macro printRegs 0
    push esp
    push ebp
    push edi
    push esi
    push edx
    push ecx
    push ebx
    push eax
    push printRegsFmt
    call _printf
    add esp, 36 ; clean up stack
%endmacro
%endif