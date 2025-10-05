// echo.asm
// receive byte over UART_RX and transmit the received byte to UART_TX
// repeat in an endless loop

@1
D=A
@LED
M=D // LED=1 (01 = LED1 on/LED2 off, program has started)

(read)
@UART_RX
D=M // D=buffer
@R0
M=D // R0=buffer
@32768 // 0x8000 (note: outside of original HACK address range)
D=D-A
@read // wait for valid byte to be set
D;JEQ

// transmit
@R0
D=M // D=buffer
@UART_TX
M=D // send buffer

(wait) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait
D;JNE // loop if busy

// rx/tx complete
@2
D=A
@LED
M=D // LED=2 (10 = LED1 off/LED2 on, success)

@read
0;JMP // loop forever
