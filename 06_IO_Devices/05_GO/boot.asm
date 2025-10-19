// Bootloader: loads 64K words of HACK code starting at SPI address 0x10000 (64K) into SRAM.
// R0=jmp_target, R1=spi_bytes, R2=read_idx, R3=write_idx, R4=odd_even
// DEBUG0= DEBUG1=spi_bytes DEBUG2=

// ====================================
// SPI: send command bytes
// ====================================

@171 // send command (0xAB=wake)
D=A
@SPI
M=D // send 0xAB

@send_csx // set next address
D=A
@R0
M=D // R0=send_csx

@wait
0;JMP // wait for SPI

// ------------------------------------

(send_csx)
@256 // send CSX=1 (execute)
D=A
@SPI
M=D

@30 // wait for for 3µs (75 cycles) for wake to execute
D=A
(delay_loop)
D=D-1 // D--
@delay_loop
D;JGE // loop

// ------------------------------------

@3 // send command (0x03=read)
D=A
@SPI
M=D // send 0x03

@send_addr_0 // set next address
D=A
@R0
M=D // R0=send_addr_0

// ------------------------------------

(wait) // wait for SPI
@SPI
D=M // check if ready (out[15] != 0x8000)
@32767 // >15 bit = signed overflow in ALU
D=D-A // sub max positive signed value (0x7FFF)
D=D-1 // sub one more for true diff (0x8000)
@wait // if D >= A busy bit set
D;JGE // loop while busy

@R0 // &<next_address>
A=M // *<next_address>
0;JMP // jump <next_address>

// ------------------------------------

// TODO: modify initial offset address
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
0;JMP // wait for SPI

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
0;JMP // wait for SPI

// ------------------------------------

(send_addr_2)
D=0
@SPI
M=D // send 0x00

@read // set next address
D=A
@R0
M=D // R0=read

@wait
0;JMP // wait for SPI

// ====================================
// SPI: read bytes
// ====================================

// TODO: read 6 words/12 bytes (testbench)
// TODO: read 64K words/128K bytes (0x0-7FFF=32768 x 4)

(read)
D=0 // send dummy byte to keep SCK rolling
@SPI
M=D // send 0x00 (MOSI is now ignored while CSX remains low)

@read0 // set next address
D=A
@R0
M=D // R0=read0

@255
D=A // D=0xFF
@R1
M=D // init spi_bytes=0xFF
@R2
M=0 // init read_idx, start at 0x0 (offset from 0x10000)
@R3
M=0 // init write_idx, start at 0x0 
@R4
M=0 // init odd_even

@wait
0;JMP // wait for SPI

// ------------------------------------

(read0)
@SPI // read spi_bytes
D=M
@R1
M=D+M // R1=spi_bytes (even=high byte, odd=low+high byte)
@DEBUG1
M=D // DEBUG1=spi_bytes

@R4
D=M // D=odd_even
@even
D;JEQ // only write every 2nd byte

// odd ~~~~~~~~~~~~~~~~
@R3
D=M // D=write_idx
@SRAM_A 
M=D // write SRAM_A[write_idx]

@R2
D=M // D=spi_bytes
@SRAM_D 
M=D // write byte to SRAM

@R3
M=M+1 // write_idx++
D=M // save write_idx

@6 // word limit // TODO: 64K (multiple loops etc)
D=D-A
@break
D;JEQ

@R4
M=M-1 // odd_even-- (reset)

@255
D=A // D=0xFF
@R1
M=D // spi_bytes=0xFF (reset)

(even) // ~~~~~~~~~~~~~~~~

@R4
M=M+1 // odd_even++

// next ~~~~~~~~~~~~~~~~

@R2
M=M+1 // read_idx++

// TODO: optimize @[0|1|-1] > D=A instructions
D=0
@SPI
M=D // send dummy byte to keep SCK rolling

@wait
0;JMP // wait for SPI (R0=read0)

// ====================================
// SPI: close the transaction
// ====================================

(break)
@256 // send 0x100 (CSX=1) to end the read
D=A
@SPI
M=D

// takes 3µs (75 cycles) to go to sleep
@185 // send command (0xB9=sleep)
D=A
@SPI
M=D // send 0xAB

@256 // send CSX=1 (execute)
D=A
@SPI
M=D

// ====================================
// GO: switch to boot mode!
// ====================================

@GO // writing any data to GO will trigger a PC reset and a
M=1 // bank switch to begin reading from SRAM instead of ROM!