// sram_boot_test.asm
// test SRAM_A/D read/write in boot mode
// use debug_sram values for debugging (may need adjustment in HACK_tb.v)
// check LED output on sim/real hardware

@SRAM_D
M=1 // A=0, M=1

@SRAM_A
MD=1 // A/D=1
@SRAM_D
MD=D+1 // M/D=2

@SRAM_A
M=D // A=2
@SRAM_D
MD=D+1 // D=3
MD=D+1
MD=D+1
MD=D+1
MD=D+1 // D=7

@100
D=0

@SRAM_D
D=M
@LED
M=D // LED=7 (111 = all LEDs on, SRAM read/write works)

(LOOP)
@LOOP
0;JMP