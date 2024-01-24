#
# Makefile for WhiteDragon user program
#

AS = riscv-none-embed-as -march=rv32im 
CC = riscv-none-embed-gcc -march=rv32im -c -O3 
LD = riscv-none-embed-ld -T ram.ld
OBJCOPY = riscv-none-embed-objcopy
OBJDUMP = riscv-none-embed-objdump 
LIBGCC =   "c:\Program Files\riscv-none-gcc\lib\gcc\riscv-none-embed\8.2.0\rv32im\ilp32\libgcc.a"
LIBSTDCC = "c:\Program Files\riscv-none-gcc\riscv-none-embed\lib\rv32im\ilp32\libstdc++.a"
LIBC     = "c:\Program Files\riscv-none-gcc\riscv-none-embed\lib\rv32im\ilp32\libc.a"
LIBM     = "c:\Program Files\riscv-none-gcc\riscv-none-embed\lib\rv32im\ilp32\libm.a" 
LIBNOSYS = "c:\Program Files\riscv-none-gcc\riscv-none-embed\lib\rv32im\ilp32\libnosys.a"

all: commanche.bin commanche.rec commanche.disasm 

commanche.disasm: commanche.elf
	$(OBJDUMP) --disassemble -S commanche.elf>commanche.disasm

commanche.rec: commanche.elf
	$(OBJCOPY) -O srec commanche.elf commanche.rec

commanche.elf: main.o bsp.o startup.o osAlloc.o osFile.o gfBitmap.o gfDrawing.o gfFont.o gfGouraud.o gfJPEG.o picojpeg.o diskio.o ccsbcs.o ff.o
	$(LD) startup.o main.o ../gfxLib/bsp.o ../gfxLib/diskio.o ../gfxLib/ccsbcs.o ../gfxLib/ff.o ../gfxLib/osAlloc.o ../gfxLib/osFile.o ../gfxLib/gfBitmap.o ../gfxLib/gfDrawing.o ../gfxLib/gfFont.o ../gfxLib/gfGouraud.o ../gfxLib/gfJPEG.o ../gfxLib/picojpeg.o $(LIBC) $(LIBNOSYS) $(LIBM) $(LIBGCC)  -o commanche.elf

commanche.bin: commanche.elf
	$(OBJCOPY) -O binary commanche.elf commanche.bin

main.o: main.cpp
	$(CC) -o main.o main.cpp 

bsp.o: ../gfxLib/bsp.cpp
	$(CC) -o ../gfxLib/bsp.o ../gfxLib/bsp.cpp 

startup.o: startup.s
	$(AS) -o startup.o startup.s

gfBitmap.o: ../gfxLib/gfBitmap.cpp
	$(CC) -o ../gfxLib/gfBitmap.o ../gfxLib/gfBitmap.cpp 
	
gfDrawing.o: ../gfxLib/gfDrawing.cpp
	$(CC) -o ../gfxLib/gfDrawing.o ../gfxLib/gfDrawing.cpp 

gfGouraud.o: ../gfxLib/gfGouraud.cpp
	$(CC) -o ../gfxLib/gfGouraud.o ../gfxLib/gfGouraud.cpp 

gfFont.o: ../gfxLib/gfFont.cpp
	$(CC) -o ../gfxLib/gfFont.o ../gfxLib/gfFont.cpp 
	
gfJPEG.o: ../gfxLib/gfJPEG.cpp
	$(CC) -o ../gfxLib/gfJPEG.o ../gfxLib/gfJPEG.cpp 

picojpeg.o: ../gfxLib/picojpeg.cpp
	$(CC) -o ../gfxLib/picojpeg.o ../gfxLib/picojpeg.cpp 

osAlloc.o: ../gfxLib/osAlloc.cpp
	$(CC) -o ../gfxLib/osAlloc.o ../gfxLib/osAlloc.cpp 

osFile.o: ../gfxLib/osFile.cpp
	$(CC) -o ../gfxLib/osFile.o ../gfxLib/osFile.cpp 

diskio.o: ../gfxLib/diskio.cpp
	$(CC) -o ../gfxLib/diskio.o ../gfxLib/diskio.cpp 

ccsbcs.o: ../gfxLib/ccsbcs.cpp 
	$(CC) -o ../gfxLib/ccsbcs.o ../gfxLib/ccsbcs.cpp

ff.o: ../gfxLib/ff.cpp
	$(CC) -o ../gfxLib/ff.o ../gfxLib/ff.cpp  
	
clean:
	rm -f *.o *.rec *.disasm *.elf *.mif *.mi *.bin
	rm -f ../gfxLib/*.o

send: commanche.rec
	srecsend commanche.rec com3 500000
	