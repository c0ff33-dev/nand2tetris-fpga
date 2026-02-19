// sram_mini_test.asm
// source for the "embedded" test program in sram_run_test.asm

@4112 // arbitrary SRAM address
M=1
A=A+1 // A=2

MD=0 // init: in case test bench pre-filled SRAM
MD=M+1
MD=M+1
MD=M+1 // M=3

@5000 // CPU/SRAM noise
M=0

@4112
D=M
@LED
M=D // LED=3 (111 = all LEDs on, SRAM read/write works)

(LOOP)
@LOOP
0;JMP 