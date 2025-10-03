// hello.asm
// Outputs "Hi" on UART_TX
// "H" = 72, "i" = 105" (ascii ordinal)

@1
D=A
@LED // likely not visible on hardware unless really clocked down
M=D // LED=1 (01 = LED1 on/LED2 off, program has started)

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

@2
D=A
@LED // likely not visible on hardware unless really clocked down
M=D // LED=2 (10 = LED1 on/LED2 off, program has started)

(HALT)
@HALT
0;JMP // end