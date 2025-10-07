// hello.asm
// Outputs "Hi" on UART_TX
// Pulse single null byte as message header
// "H" = 72 (0x48), "i" = 105 (0x69)
// "\r" = 13 (0x0D), "\n" = 10 (0x0A)

@0
D=A // D=0
@UART_TX
M=D // send "<null>" (sync byte)

(wait0) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait0
D;JNE // loop if busy

// -------------------------------

@72
D=A // D = "H"
@UART_TX
M=D // send "H"

(wait1) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait1
D;JNE // loop if busy

// -------------------------------

@105
D=A // D = "i"
@UART_TX
M=D // send "i"

(wait2) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait2
D;JNE // loop if busy

// -------------------------------

@13
D=A // D = "\r"
@UART_TX
M=D // send "\r"

(wait3) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait3
D;JNE // loop if busy

// -------------------------------

@10
D=A // D = "\n"
@UART_TX
M=D // send "\n"

(HALT)
@HALT
0;JMP // end