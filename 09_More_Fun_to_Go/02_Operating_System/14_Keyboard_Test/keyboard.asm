// keyboard.asm
// read the keyboard state and output to LED

// KBD is mapped to address 24576 (nand2tetris standard)
// When a key is pressed on the PS/2 keyboard, its ASCII
// value appears at @KBD. When no key is pressed, KBD == 0.

// This program polls the keyboard for the 'a' key (ASCII 97)
// and turns on LED1/2 when detected.

@LED
M=1 // LED1 on (program started)

(LOOP)
@24576 // KBD label not implemented in assembler
D=M // read keyboard

@97
D=D-A // check == 0x61 ("a")
@BREAK
D;JEQ

@LOOP
0;JMP

(BREAK)
@3
D=A
@LED
M=D // LED1/2 on (keystroke detected)

(HALT)
@HALT
0;JMP
