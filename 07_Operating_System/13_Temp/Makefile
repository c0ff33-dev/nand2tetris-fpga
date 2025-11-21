PYTHON = python3.11 # linux
# PYTHON = python # windows

all: jack vm asm bin sim

jack:
	$(PYTHON) ../../tools/JackCompiler/JackCompiler.pyc ./
vm:
	$(PYTHON) ../../tools/VMTranslator/VMTranslator.pyc ./
asm:
	$(PYTHON) ../../tools/Assembler/assembler.pyc out.asm
bin:
	$(PYTHON) ../../tools/AsciiToBin.py out.hack
sim:
	cp out.hack ../00_HACK/ROM.hack
	cp out.hack ../../06_IO_Devices/00_HACK/ROM.hack
upload:
	iceprogduino -o 64k -w out.bin
# winiceprogduino doesn't support -o so need some other solution here
win_upload: 
	..\..\tools\winiceprogduino\winiceprogduino.exe -ICOM3 -o 64k -w out.bin
clean:
	rm -f *.vm *.asm *.hack *.bin *~

.PHONY: all clean
