PYTHON = python3.11
PYTHON12 = python3.12

all: jack vm asm bin sim

jack:
	$(PYTHON) ../../tools/JackCompiler/JackCompiler.pyc ./
vm:
	$(PYTHON12) ../../tools/VMTranslator/VMTranslator.pyc ./
asm:
	$(PYTHON) ../../tools/Assembler/assembler.pyc out.asm
bin:
	$(PYTHON) ../../tools/AsciiToBin.py out.hack
sim:
	cp out.hack ../00_HACK_OS/ROM.hack
upload:
	iceprogduino -o 64k -w out.bin
clean:
	rm -f *.vm *.asm *.hack *.bin *~
pong:
	rm -f *.vm *.asm *.hack *.bin *~
	cp ../../../nand2tetris/projects/13/Pong/Pong.hack ./out.hack
	$(PYTHON) ../../tools/AsciiToBin.py out.hack
.PHONY: all clean
