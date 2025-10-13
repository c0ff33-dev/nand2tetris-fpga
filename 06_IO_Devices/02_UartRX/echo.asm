// echo.asm
// receive byte over UART_RX and transmit the received byte to UART_TX
// repeat in an endless loop.
// out[15]=1 (ready), write any data to clear
// out[7:0] (byte), latched to only be in either state

@1
D=A
@LED
M=D // LED=1 (01 = LED1 on/LED2 off, program has started)

@UART_RX
M=1 // init the RX buffer

(read)
@UART_RX 
D=M // D=rx
@R0
M=D // R0=rx

// warning: this only works because its diff'd against itself
// >15 bit numbers can overflow the ALU (see cat.asm)
@32768 // check out[15] (0x8000)
D=A-D
@read // loop until rx written
D;JEQ

@UART_RX
M=1 // clear the RX buffer once read (now saved in R0)

@2
D=A
@LED
M=D // LED=2 (10 = LED1 off/LED2 on, rx done)

// transmit
@R0
D=M // D=buffer
@UART_TX
M=D // send byte

(wait) // wait for tx (2170 cycles)
@UART_TX
D=M // check if ready
@wait
D;JNE // loop if busy

@3 // rx/tx complete
D=A // D=3
@LED
M=D // LED=3 (11 = LED1/2 on, tx done)
@read
0;JMP // loop forever