PYTHON = /bin/python3.11

screen:
	$(PYTHON) ../../../tools/Assembler/assembler.pyc screen.asm
upload:
	$(PYTHON) ../../../tools/Assembler/assembler.pyc screen.asm
	$(PYTHON) ../../../tools/AsciiToBin.py screen.hack
	iceprogduino -o 64k -w screen.bin
clean:
	rm -f *.hack *~ *.bin

.PHONY: clean
