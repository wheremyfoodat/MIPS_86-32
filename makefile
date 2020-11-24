mainmake: main.asm 
	nasm -f win32 main.asm
	gcc -m32 main.obj -o main.exe
	.\main