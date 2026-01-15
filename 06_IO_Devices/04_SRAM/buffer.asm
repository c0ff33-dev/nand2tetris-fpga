// read 4 bytes of text file from SPI starting at address 0x040000 and write
// the string to SRAM. Finally read the string from SRAM and send
// the string to UART_TX
//
// load spi flash rom starting at address 0x040000 and write the data to UART_TX
// read command is 0x03 followed by 3 x address bytes
// e.g. send read data command @ 0x40000 [256k]: 0x03, 0x04, 0x00, 0x00
// out[15]=1 (busy), [7:0] continues shifting while busy
//
// SRAM_A = SRAM address register, updates in [t+1]
// SRAM_D = SRAM data register, updates in [t+1], persists last result from [t+1]
//
// R0=jmp address for SPI loops
// R1-4=SPI (ROM) bytes, R5-8=SRAM bytes
// DEBUG0=checksum, DEBUG1-3=SPI/SRAM (ADDR/DATA) bytes

// ====================================
// SPI: send command bytes
// ====================================

@171 // send command (0xAB=wake)
D=A
@SPI
M=D // send 0xAB

@DEBUG0
M=D // accumulate

@send_csx // set next address
D=A
@R0
M=D // R0=send_csx

@wait
0;JMP // wait for current byte to send

// ------------------------------------

(send_csx)
@256 // send CSX=1 (execute)
D=A
@SPI
M=D

@DEBUG0
M=D+M // accumulate

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

@DEBUG0
M=D+M // accumulate

@send_addr_0 // set next address
D=A
@R0
M=D // R0=send_addr_0

// ------------------------------------

(wait) // wait for spi
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
@4
D=A
@SPI
M=D // send 0x04

@DEBUG0
M=D+M // accumulate

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

@DEBUG0
M=D+M // accumulate

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

@DEBUG0
M=D+M // accumulate

@read // set next address
D=A
@R0
M=D // R0=read

@wait
0;JMP // wait for current byte to send

// ====================================
// SPI: read bytes
// ====================================

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

@R1 // save SPI char
M=D
@DEBUG1
M=D // emit SPI char to DEBUG1

@0 // start at SRAM_ADDR=0x0
D=A
@SRAM_A // write SRAM_A
M=D
@DEBUG2
M=D // emit SRAM_ADDR to DEBUG2

@R1
D=M // restore SPI char
@SRAM_D // write char to SRAM
M=D
D=M // read char back from SRAM
@DEBUG3
M=D // emit to DEBUG3

@UART_TX
M=D // transmit byte

(tx0) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@tx0
D;JNE // loop if busy

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

@R1 // save SPI char
M=D
@DEBUG1
M=D // emit SPI char to DEBUG1

@SRAM_A // write SRAM_A (++)
M=M+1
D=M // read SRAM_A
@DEBUG2
M=D // emit SRAM_ADDR to DEBUG2

@R1
D=M // restore SPI char
@SRAM_D // write char to SRAM
M=D
@DEBUG3
M=D // emit to DEBUG3

@UART_TX
M=D // send byte

(tx1) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@tx1
D;JNE // loop if busy

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

@R1 // save SPI char
M=D
@DEBUG1
M=D // emit SPI char to DEBUG1

@SRAM_A // write SRAM_A (++)
M=M+1
D=M // read SRAM_A
@DEBUG2
M=D // emit SRAM_ADDR to DEBUG2

@R1
D=M // restore SPI char
@SRAM_D // write char to SRAM
M=D
@DEBUG3
M=D // emit to DEBUG3

@UART_TX
M=D // send byte

(tx2) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@tx2
D;JNE // loop if busy

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

@R1 // save SPI char
M=D
@DEBUG1
M=D // emit SPI char to DEBUG1

@SRAM_A // write SRAM_A (++)
M=M+1
D=M // read SRAM_A
@DEBUG2
M=D // emit SRAM_ADDR to DEBUG2

@R1
D=M // restore SPI char
@SRAM_D // write char to SRAM
M=D
@DEBUG3
M=D // emit to DEBUG3

@UART_TX
M=D // send byte

(tx3) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@tx3
D;JNE // loop if busy

// ====================================
// SPI: close the transaction
// ====================================

@256 // send 0x100 (CSX=1) to end the read
D=A
@SPI
M=D

@DEBUG0
M=D+M // accumulate

// takes 3µs (75 cycles) to go to sleep
@185 // send command (0xB9=sleep)
D=A
@SPI
M=D // send 0xAB

@DEBUG0
M=D+M // accumulate

@256 // send CSX=1 (execute)
D=A
@SPI
M=D

@DEBUG0
M=D+M // accumulate

// ====================================
// SPI: error checking
// ====================================

// Check result and HALT
@DEBUG0
D=M // read accumulated result

@1131 // expected (0x046B)
D=D-A // D = result - expected
@OK
D;JEQ // OK if result == expected

// ERROR
@3
D=A // D=3
@LED
M=D // LED=3 (11 = LED1/2 on, error)
@HALT
0;JMP // end

(OK)
@2
D=A // D=2
@LED
M=D // LED=2 (10 = LED1 off/LED2 on, success)

// ====================================
// end
// ====================================

(HALT)
@HALT
0;JMP // end