// Bootloader: loads 64K words of HACK code starting at SPI address 0x10000 (64K) into SRAM.
// R0=jmp_target, R1=spi_byte, R2=outer_loop, R3=write_idx, R4=odd_even, R5=spi_sum, R6=inner_idx
// DEBUG1=spi_byte, DEBUG2=spi_sum

// FUTURE: optimize @[0|1|-1] > D=A instructions & M=D[0|1|-1] instructions (globally)

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

// special note on ALU overflows
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// 0x8000 is interpreted as -32768 (max neg) so addition 
// actually works and keeps going "higher" back towards zero
// - this 16 bit value is fine for M/D assignment ops as well
//
// but subtraction (2s complement addition) will break when the
// subtracting value is larger than 32767 (0x7FFF) but using multiple
// rounds of subtraction with a value <= 32767 will work

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

(send_addr_0)
@SPI
M=1 // send 0x01

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

(read)
D=0 // send dummy byte to keep SCK rolling
@SPI
M=D // send 0x00 (MOSI is now ignored while CSX remains low)

@read0 // set next address
D=A
@R0
M=D // R0=read0

@R1
M=0 // init spi_byte=0x0
@R2
M=1
M=M+1 // init outer_loop=2
@R3
M=0 // init write_idx, start at 0x0
@R4
M=0 // init odd_even
@R5
M=0 // init spi_sum

@wait
0;JMP // wait for SPI

// ------------------------------------

(read0)
@SPI // read spi_byte
D=M

@R1 
M=D // R1=spi_byte (original)

@DEBUG1
M=D // DEBUG1=spi_byte

@R4
D=M // D=odd_even
@odd
D;JNE // only shift even bytes and write odd bytes

// even ~~~~~~~~~~~~~~~~

// shift first byte (hi_byte) left by 8
// even with ALU overflow this should still work
@R1
D=M   // D=spi_byte[0]
@R5
M=D   // spi_sum=spi_byte   
D=D+M // D=2 x spi_byte
M=D   // spi_sum=2 x spi_byte
D=D+M // D=4 x spi_byte
M=D   // spi_sum=4 x spi_byte
D=D+M // D=8 x spi_byte
M=D   // spi_sum=8 x spi_byte
D=D+M // D=16 x spi_byte
M=D   // spi_sum=16 x spi_byte
D=D+M // D=32 x spi_byte
M=D   // spi_sum=32 x spi_byte
D=D+M // D=64 x spi_byte
M=D   // spi_sum=64 x spi_byte
D=D+M // D=128 x spi_byte
M=D   // spi_sum=128 x spi_byte
D=D+M // D=256 x spi_byte
M=D   // spi_sum=256 x spi_byte

@DEBUG2
M=D // DEBUG2=spi_sum

@R4
M=M+1 // odd_even++

@next
0;JMP

(odd) // ~~~~~~~~~~~~~~~~

@R1
D=M // D=spi_byte[1]

@DEBUG1
M=D // DEBUG1=spi_byte

@R5
M=D+M // spi_sum=hi_byte:low_byte
D=M // D=spi_sum

@DEBUG2
M=D // DEBUG2=spi_sum

@R3
D=M // D=write_idx
@SRAM_A 
M=D // SRAM_A=write_idx

@R5
D=M // D=spi_sum
@SRAM_D 
M=D // SRAM[write_idx]=spi_sum

@R3 // will overflow ALU so don't use in cmp
M=M+1 // write_idx++ (still works all the way to 0xFFFF)
@R6 // reset at 0x7FFF (15 bits for ALU cmp)
M=M+1 // inner_idx++
D=M // copy inner_idx

@R4
M=M-1 // odd_even-- (reset)

@R1
M=0 // spi_byte=0x0 (reset)

@32767 // inner loop word limit (0x7FFF)
D=D-A // inner_idx
@break_inner
D;JEQ

(next) // ~~~~~~~~~~~~~~~~

@SPI
M=0 // send dummy byte to keep SCK rolling

@wait
0;JMP // wait for SPI (R0=read0)

// ====================================
// SPI: close the transaction
// ====================================

(break_inner)
@R6
M=0 // reset to prevent overflow
@R2
MD=M-1 // outer_loop--
@next // run 32768 x 2 times
D;JNE // 1 write per word = exactly 64K words

// break ~~~~~~~~~~~~~~~~
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