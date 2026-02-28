PYTHON = python3.11
PYTHON12 = python3.12

all: jack vm asm bin sim

screen:
	$(PYTHON) ../../../tools/Assembler/assembler.pyc screen.asm
	$(PYTHON) ../../../tools/AsciiToBin.py screen.hack
	cp -f screen.bin out.bin
jack:
	$(PYTHON) ../../../tools/JackCompiler/JackCompiler.pyc ./
vm:
	$(PYTHON12) ../../../tools/VMTranslator/VMTranslator.pyc ./
asm:
	$(PYTHON) ../../../tools/Assembler/assembler.pyc out.asm
bin:
	$(PYTHON) ../../../tools/AsciiToBin.py out.hack
sim:
	cp out.hack ../../00_HACK_OS/ROM.hack
upload:
	iceprogduino -o 64k -w out.bin
clean:
	rm -f *.vm *.asm *.hack *.bin *~

.PHONY: all clean
