ASSEMBLER=nasm
ASSEMBLERFLAGS=-f win32
LINKERFLAGS=-m32
SRCFILES=main.asm
OBJFILE=main.obj
EXEFILE=main.exe

mainmake: main.asm 
	nasm -f win32 main.asm
	gcc -m32 main.obj -o main.exe
	.\main