PYTHON = python3.11
PYTHON12 = python3.12

all: jack vm asm bin sim

jack:
	$(PYTHON12) ../../tools/JackCompiler/tokenizer.pyc ./
	$(PYTHON12) ../../tools/JackCompiler/analyzer.pyc ./
	$(PYTHON12) ../../tools/JackCompiler/compiler.pyc ./
vm:
	$(PYTHON12) ../../tools/VMTranslator/translator.pyc ./
asm:
	$(PYTHON12) ../../tools/Assembler/assembler.pyc out.asm
bin:
	$(PYTHON) ../../tools/AsciiToBin.py out.hack
sim:
	cp out.hack ../00_HACK/ROM.hack
upload:
	iceprogduino -o 64k -w out.bin
clean:
	rm -f *.xml *.vm *.asm *.hack *.bin *~

.PHONY: all clean
