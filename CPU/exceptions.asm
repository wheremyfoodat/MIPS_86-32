%ifndef EXCEPTIONS_ASM
%define EXCEPTIONS_ASM

%include "CPU\cpu.asm"
%include "include\cpu.inc"

extern _printf
extern _exit

section .data
    exception_error: db "Exception occured! Aborting!", 0

section .text

throwException:
    push exception_error ; print error
    call _printf
    add esp, 4 ; clean up stack
    call _exit ; abort

%endif