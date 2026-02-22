// Fill VRAM with black pixels (0xFFFF)

@16383
D=A
@R0
M=D // R0=0x3FFF (pre-increment VRAM start)

// 57343 (0xDFFF) is the largest A instruction that won't
// be misinterpreted as a C instruction, -1 is not an ALU
// overflow but instead relies on the signed representation
// being the same as unsigned 0xFFFF
@0
D=A
D=D-1 // D=0xFFFF (fill word)

(LOOP)
@R0
AM=M+1 // inc VRAM address & jump to it
M=D // write fill word
@LOOP
0;JMP
