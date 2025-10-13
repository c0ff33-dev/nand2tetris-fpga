// hello.asm
// Outputs "Hi\r\n" on UART_TX
// out[15]=1 (busy) or out[15]=0 (ready)

// ===============================
// sync / send message header
// ===============================

// @0
// D=A // D=null
// @UART_TX
// M=D // send null (clear the line)

// (wait0) // wait for tx (2170 cycles)
// @UART_TX
// D=M // check if ready
// @wait0
// D;JNE // loop if busy

// -------------------------------

// @222
// D=A // D=0xDE
// @UART_TX
// M=D // send byte

// (wait1) // wait for tx (2170 cycles)
// @UART_TX
// D=M // check if ready
// @wait1
// D;JNE // loop if busy

// -------------------------------

// @173
// D=A // D=0xAD
// @UART_TX
// M=D // send byte

// (wait2) // wait for tx (2170 cycles)
// @UART_TX
// D=M // check if ready
// @wait2
// D;JNE // loop if busy

// ===============================
// send message
// ===============================

@72
D=A // D = "H" (0x48)
@UART_TX
M=D // send byte

@DEBUG0
M=D // accumulate

(wait3) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait3
D;JNE // loop if busy

// -------------------------------

@105
D=A // D = "i" (0x69)
@UART_TX
M=D // send byte

@DEBUG0
M=D+M // accumulate

(wait4) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait4
D;JNE // loop if busy

// -------------------------------

@13
D=A // D = "\r" (0x0D)
@UART_TX
M=D // send byte

@DEBUG0
M=D+M // accumulate

(wait5) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait5
D;JNE // loop if busy

// -------------------------------

@10
D=A // D = "\n" (0x0A)
@UART_TX
M=D // send byte

@DEBUG0
M=D+M // accumulate

(wait6) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait6
D;JNE // loop if busy

// ===============================
// send message footer
// ===============================

// @190
// D=A // D=0xBE
// @UART_TX
// M=D // send byte

// (wait7) // wait for tx (2170 cycles)
// @UART_TX
// D=M // check if ready
// @wait7
// D;JNE // loop if busy

// -------------------------------

// @239
// D=A // D=0xEF
// @UART_TX
// M=D // send byte

// (wait8) // wait for tx (2170 cycles)
// @UART_TX
// D=M // check if ready
// @wait8
// D;JNE // loop if busy

// ===============================
// end
// ===============================

// Check result and HALT
@DEBUG0
D=M // read accumulated result
@UART_TX
M=D // send debug result for good measure

@200 // expected (0xC8)
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

(HALT)
@HALT
0;JMP // end