// sram_boot_test.asm
// test SRAM_A/D read/write in boot mode
// check debug_sram[0:2] in test bench
// check LED output on real hardware

@10
D=A
@SRAM_A
M=D // A=10

@SRAM_D
MD=D+1 // D=11

@SRAM_A
M=D // A=11
@SRAM_D
MD=D+1 // D=12

@SRAM_A
M=D // A=12
@SRAM_D
MD=D+1 // D=13
MD=D+1
MD=D+1 // D=15

@SRAM_D
D=M
@LED
M=D // LED=15 (111 = all LEDs on, SRAM read/write works)

(LOOP)
@LOOP
0;JMP