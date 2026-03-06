PYTHON = python3.11
PYTHON12 = python3.12

leds:
	$(PYTHON12) ../tools/Assembler/assembler.pyc leds.asm
	$(PYTHON) ../tools/AsciiToBin.py leds.hack
	cp leds.hack ../05_Computer_Architecture/04_HACK/ROM.hack
mult:
	$(PYTHON12) ../tools/Assembler/assembler.pyc mult.asm
	cp mult.hack ../05_Computer_Architecture/04_HACK/ROM.hack
memory:
	$(PYTHON12) ../tools/Assembler/assembler.pyc memory.asm
	cp memory.hack ../05_Computer_Architecture/04_HACK/ROM.hack
upload:
	iceprogduino -o 64k -w leds.bin
clean:
	rm -f *.hack *~ *.bin

.PHONY: clean
