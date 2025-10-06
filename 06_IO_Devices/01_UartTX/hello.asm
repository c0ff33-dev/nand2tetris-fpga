// hello.asm
// Outputs "Hi" on UART_TX
// "H" = 72, "i" = 105, "\n" = 128 (ascii ordinal)

@72
D=A // D = "H"
@UART_TX
M=D // send "H"

(wait) // wait for tx (2170 cycles)
@1
D=A
@LED
M=D // LED=1 (01 = LED1 on/LED2 off, wait1)

@UART_TX
D=M // check if ready
@wait
D;JNE // loop if busy

@105
D=A // D = "i"
@UART_TX
M=D // send "i"

(wait2) // wait for tx (2170 cycles)
@2
D=A
@LED
M=D // LED=2 (10 = LED1 off/LED2 on, wait2)

@UART_TX
D=M // check if ready
@wait2
D;JNE // loop if busy

@128
D=A // D = "\n"
@UART_TX
M=D // send "\n"

(wait3) // wait for tx (2170 cycles)
@3
D=A
@LED
M=D // LED=3 (11 = LED1/2 on, done)

@UART_TX
D=M // check if ready
@wait3
D;JNE // loop if busy

(HALT)
@0
D=A
@LED
M=D // LED=0 (00 = LED1/2 off, program has ended)

@HALT
0;JMP // end