// hello.asm
// Outputs "Hi\r\n" on UART_TX
// Pulse single byte to clear the line
// And 0xDEAD / 0xBEEF as message header/footer
// Filtering applied at arduino (iceprog2.ino)

// ===============================
// sync / send message header
// ===============================

@0
D=A // D=null
@UART_TX
M=D // send null (clear the line)

// TODO: check out[15] (32768) only not whole value
// TODO: use repeatable wait function

(wait0) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait0
D;JNE // loop if busy

// -------------------------------

@222
D=A // D=0xDE
@UART_TX
M=D // send 0xDE

(wait1) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait1
D;JNE // loop if busy

// -------------------------------

@173
D=A // D=0xAD
@UART_TX
M=D // send 0xAD

(wait2) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait2
D;JNE // loop if busy

// ===============================
// send message
// ===============================

@72
D=A // D = "H"
@UART_TX
M=D // send "H"

(wait3) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait3
D;JNE // loop if busy

// -------------------------------

@105
D=A // D = "i"
@UART_TX
M=D // send "i"

(wait4) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait4
D;JNE // loop if busy

// -------------------------------

@13
D=A // D = "\r"
@UART_TX
M=D // send "\r"

(wait5) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait5
D;JNE // loop if busy

// -------------------------------

@10
D=A // D = "\n"
@UART_TX
M=D // send "\n"

(wait6) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait6
D;JNE // loop if busy

// ===============================
// send message footer
// ===============================

@190
D=A // D=0xBE
@UART_TX
M=D // send 0xBE

(wait7) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait7
D;JNE // loop if busy

// -------------------------------

@239
D=A // D=0xEF
@UART_TX
M=D // send 0xEF

(wait8) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait8
D;JNE // loop if busy

// ===============================
// end
// ===============================

(HALT)
@HALT
0;JMP // end