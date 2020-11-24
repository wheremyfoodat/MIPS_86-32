%ifndef MACROS_ASM
%define MACROS_ASM

extern _printf
extern _fopen
extern _fread

section .data:
fileReadFailMsg: db "Failed to read file %s :(", 0xA, 0
fileReadSuccessMsg: db "Successfully opened file %s! :)", 0xA, 0
printRegsFmt: db "eax: %08X, ebx: %08X", 0xA, "ecx: %08X, edx: %08X", 0xA, "esi: %08X, edi: %08X", 0xA, "ebp: %08X, esp: %08X", 0xA, 0
printMIPSRegsFmt:
        db "pc: %08X", 0xA
        db "$zero: %08X, $at: %08X, $v0: %08X, $v1: %08X", 0xA
        db "$a0: %08X, $a1: %08X, $a2: %08X, $a3: %08X", 0xA
        db "$t0: %08X, $t1: %08X, $t2: %08X, $t3: %08X", 0xA
        db "$t4: %08X, $t5: %08X, $t6: %08X, $t7: %08X", 0xA
        db "$s0: %08X, $s1: %08X, $s2: %08X, $s3: %08X", 0xA
        db "$s4: %08X, $s5: %08X, $s6: %08X, $s7: %08X", 0xA
        db "$t8: %08X, $t9: %08X, $k0: %08X, $k1: %08X", 0xA
        db "$gp: %08X, $sp: %08X, $fp: %08X, $ra: %08X", 0xA, 0

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


%macro pushall 0 ; pusha is deprecated in x64. I use this instead of pusha so that I can port to x64 
    push ebp
    push edi
    push esi
    push edx
    push ecx
    push ebx
    push eax
%endmacro

%macro popall 0 ; popa is deprecated in x64. I use this instead of pusha so that I can port to x64 
    pop eax
    pop ebx
    pop ecx
    pop edx
    pop esi
    pop edi
    pop ebp
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

    ; print CPU regs 0-31 && pc
%macro printMIPSRegs 0 
    pushall
    mov edx, 32
.loop:
    dec edx
    push dword [processor + edx * 4]
    jnz .loop

    push dword [processor + pc]
    push printMIPSRegsFmt
    call _printf

    add esp, (34 * 4) ; clean up stack
    popall
    %endmacro
%endif
