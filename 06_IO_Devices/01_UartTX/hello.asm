// hello.asm
// Outputs "Hi\r\n" on UART_TX
// literals = ascii ordinals
// "H" = 72 (0x48)
// "i" = 105 (0x69)
// "\r" [carriage return] = 13 (0x0D) 
// "\n" [line feed] = 10 (0x0A)

@72
D=A // D = "H"
@UART_TX
M=D // send "H"

(wait) // wait for tx (2170 cycles)
@1
D=A
@LED
M=D // LED=1 (01 = LED1 on/LED2 off, wait)

@UART_TX
D=M // check if ready
@wait
D;JNE // loop if busy

// ---------------------------------------

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

// ---------------------------------------

@13
D=A // D = "\r"
@UART_TX
M=D // send "\r"

(wait3) // wait for tx (2170 cycles)
@3
D=A
@LED
M=D // LED=3 (11 = LED1/2 on, wait3)

@UART_TX
D=M // check if ready
@wait3
D;JNE // loop if busy

// ---------------------------------------

@10
D=A // D = "\n"
@UART_TX
M=D // send "\n"

@0
D=A
@LED
M=D // LED=0 (00 = LED1/2 off, wait4)

(wait4) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait4
D;JNE // loop if busy

// ---------------------------------------

@1
D=A
@LED
M=D // LED=1 (01 = LED1 on/LED2 off, end)

(HALT)
@HALT
0;JMP // end