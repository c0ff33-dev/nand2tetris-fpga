// hello.asm
// Outputs "Hi" on UART_TX
// "H" = 72, "i" = 105, "\n" = 128 (ascii ordinal)

@72
D=A // D = "H"
@UART_TX
M=D // send "H"

(HALT)
@HALT
0;JMP // end