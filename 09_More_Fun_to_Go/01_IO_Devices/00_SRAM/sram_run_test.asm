// sram_run_test.asm
// test SRAM_A/D read/write in boot mode
// use debug_sram values for debugging (may need adjustment in HACK_tb.v)
// check LED output on sim/real hardware
// see sram_mini_test.asm for full source/comments
// check LED=1 and 69649(65536+4113)==3

//  0: 0001000000010000 // 4112	 // 0x1010 // @4112
//  1: 1110111111001000 // 61384 // 0xEFC8 // M=1
//  2: 1110110111100000 // 60896 // 0xEDE0 // A=A+1
//  3: 1110101010011000 // 60056 // 0xEA98 // MD=0
//  4: 1111110111001000 // 64984 // 0xFDD8 // MD=M+1
//  5: 1111110111001000 // 64984 // 0xFDD8 // MD=M+1
//  6: 1111110111001000 // 64984 // 0xFDD8 // MD=M+1
//  7: 0001001110001000 // 5000  // 0x1388 // @5000
//  8: 1110101010001000 // 60040 // 0xEA88 // M=0
//  9: 0001000000010000 // 4112  // 0x1010 // @4112
// 10: 1111110000010000 // 64528 // 0xFC10 // D=M
// 11: 0001000000000000 // 4096  // 0x1000 // @LED
// 12: 1110001100001000 // 58120 // 0xE308 // M=D
// 13: 0000000000001100 //    12 // 0x000C // (LOOP), @LOOP 
// 14: 1110101010000111 // 60039 // 0xEA87 // 0;JMP

// in the only case where this matters (boot.asm)
// SRAM_A is explicitly initialized so we do the same here
@4112
D=A
@SRAM_A 
M=0
@SRAM_D
M=D

// split >15 bit numbers first :/
// @61384
@32767
D=A
@28617
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @60896
@32767
D=A
@28129
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @60056
@32767
D=A
@27289
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @64984
@32767
D=A
@32217
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @64984
@32767
D=A
@32217
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @64984
@32767
D=A
@32217
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

@5000
D=A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @60040
@32767
D=A
@27273
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @4112
@4112
D=A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @64528
@32767
D=A
@31761
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

@4096
D=A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @58120
@32767
D=A
@25353
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

@12
D=A
@SRAM_A
M=M+1
@SRAM_D
M=D

// @60039
@32767
D=A
@27272
D=D+A
@SRAM_A
M=M+1
@SRAM_D
M=D

@GO
M=1