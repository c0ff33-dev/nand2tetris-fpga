// Fill VRAM with an arbitrary pixel pattern (in this case all black).
// The letterboxing is an artifact of VGA being locked to 640x480 resolution
// which is larger than the original nand2tetris SCREEN, see VGA.v for details.

// SRAM memory will power on in an initially uninitialized state
// which will look like a static pixel mosaic. Doing a soft reset 
// or application upload is not sufficient to clear state between 
// runs if there happen to be runtime issues that prevent VRAM from
// being overwritten.

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
@R1
M=D // cache fill word

(LOOP)
@R0
AM=M+1 // inc VRAM address & jump to it
@R1
D=M // restore fill word
@R0
A=M
M=D // write fill word

// continue while current VRAM address < 24575
D=A
@24575
D=D-A
@LOOP
D;JLT

(END)
@END
0;JMP
