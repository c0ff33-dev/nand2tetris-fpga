// sram_mini_test.asm
// source for the "embedded" test program in sram_run_test.asm

@4112 // 69648 w/ offset, arbitrary SRAM address
M=1
A=A+1 // A=4113 (69649)

MD=0 // init: in case test bench pre-filled SRAM
MD=M+1
MD=M+1
MD=M+1 // M=3

@5000 // 70536, CPU/SRAM noise
M=0

@4112 // 69649
D=M
@LED
M=D // LED=1 (01 = LED1 on/LED2 off, SRAM read/write works)

(LOOP)
@LOOP
0;JMP 