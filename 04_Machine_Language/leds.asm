// led.asm
// execute an infinite loop to
// read the button state and output to led

(LOOP)
@BUT // store button state (inverted)
D=M  // 0 = pushed down, 1 = released

@LED // update LED state
M=D // 0 = LED off, 1 = LED on

@LOOP
0;JMP
