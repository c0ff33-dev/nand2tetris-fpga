// hello.asm
// Outputs "Hi" on UART_TX
// "H" = 72, "i" = 105" (ascii ordinal)

@72
D=A // D = "H"
@UART_TX
M=D // send "H"

(wait) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait
D;JNE // loop if busy

@105
D=A // D = "i"
@UART_TX
M=D // send "i"

(HALT)
@HALT
0;JMP // end