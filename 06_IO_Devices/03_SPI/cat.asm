// cat.asm
//
// load spi flash rom starting at address 0x040000 and write the
// data to UART_TX
//
// pre-flash the data to read on W25Q16BV
// echo SPI! > spi.txt
// iceprogduino -o 256k -w spi.txt

// FIXME: try without manipulating power states first
// TODO: send wake command (0xAB), wait 3μs
// TODO: send read data command @ 0x40000 [256k] (0x03, 0x04, 0x00, 0x00) x 4 consecutive bytes
// TODO: send sleep command (0xB9)

// TODO: Use a loop where index is R0-15?

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

@end_read // set next address
D=A
@R0
M=D // R0=end_read

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(end_read)
@SPI
D=M // read the result (stable until next write)

@DEBUG0
M=D // debug: save the result

@256 // send 0x100 (CSX=1) to end the read
D=A
@SPI
M=D // CSX=1 runs SCK and overwrites out

// ------------------------------------

(HALT)
@HALT
0;JMP // end