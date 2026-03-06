PYTHON = python3.11
PYTHON12 = python3.12

NAME = buffer

all: asm install

asm:
	$(PYTHON12) ../../tools/Assembler/assembler.pyc $(NAME).asm
install:
	cp $(NAME).hack ../00_HACK/ROM.hack
clean:
	rm -f *.hack *~

.PHONY: all clean
