// cat.asm
//
// load spi flash rom starting at address 0x040000 and write the
// data to UART_TX
//
// pre-flash the data to read on W25Q16BV
// echo SPI! > spi.txt
// iceprogduino -o 256k -w spi.txt
// 
// read command is 0x03 followed by 3 x address bytes
// e.g. send read data command @ 0x40000 [256k]: 0x03, 0x04, 0x00, 0x00

// TODO: Use a loop where index is R0-15?
// TODO: big gap between when available (immediately after read cycles) + when emitted?

@3 // send command (0x03=read)
D=A
@SPI
M=D // send 0x03

@send_addr_0 // set next address
D=A
@R0
M=D // R0=send_addr_0

// ------------------------------------

(wait) // wait for spi (16 cycles)
@SPI
D=M // check if ready
@32768 // 0x100 = 1 0000 0000
D=D-A // if D >= 0 busy bit set
@wait
D;JGE // loop while busy

@R0 // &<next_address>
A=M // *<next_address>
0;JMP // jump <next_address>

// ------------------------------------

(send_addr_0)
@4
D=A
@SPI
M=D // send 0x04

@send_addr_1 // set next address
D=A
@R0
M=D // R0=send_addr_1

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(send_addr_1)
@0
D=A
@SPI
M=D // send 0x00

@send_addr_2 // set next address
D=A
@R0
M=D // R0=send_addr_2

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(send_addr_2)
@0
D=A
@SPI
M=D // send 0x00

@read // set next address
D=A
@R0
M=D // R0=read

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(read) // send dummy byte to keep SCK rolling
@0
D=A
@SPI
M=D // send 0x00 (MOSI is now ignored while CSX remains low)

@read0 // set next address
D=A
@R0
M=D // R0=read0

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(read0)
@SPI // read emitted byte (char)
D=M 
@DEBUG0
M=D

@0
D=A
@SPI
M=D // send 0x00

@read1 // set next address
D=A
@R0
M=D // R0=read1

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(read1)
@SPI // read emitted byte (char)
D=M 
@DEBUG0
M=D

@0
D=A
@SPI
M=D // send 0x00

@read2 // set next address
D=A
@R0
M=D // R0=read2

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(read2)
@SPI // read emitted byte (char)
D=M 
@DEBUG0
M=D

@0
D=A
@SPI
M=D // send 0x00

@read3 // set next address
D=A
@R0
M=D // R0=read3

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(read3)
@SPI // read emitted byte (char)
D=M 
@DEBUG0
M=D

// ------------------------------------

// FIXME: CSX doesn't stay low and instead falls into some kind of feedback loop
@256 // send 0x100 (CSX=1) to end the read
D=A
@SPI
M=D

// ------------------------------------

(HALT)
@HALT
0;JMP // end // FIXME: PC=0x6C, EA87 (jmp) to 0x6B, seems to go off the rails for some reason