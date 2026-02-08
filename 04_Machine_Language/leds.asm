// led.asm
// execute an infinite loop to
// read the button state and output to LED

// LED1/2 on when BUT1/2 released & off when pushed respectively
// LED and BUT are 2 bit wires that will split into their 
// respective physical pins for LED1/2 and BUT1/2

// BUT = high when released, low when pushed
// LED = low when off, high when on
// 00 (0) = both LED1/2 off, both BUT1/2 pushed
// 01 (1) = LED1 on/LED2 off, BUT1 released/BUT2 pushed
// 10 (2) = LED1 off/LED2 on, BUT1 pushed/BUT2 released
// 11 (3) = LED1/2 on, BUT1/2 released

// Put your code here:
@SRAM_D
MD=D+1
MD=D+1
MD=D+1
@SRAM_D
D=M
@LED
M=D

(LOOP)
@LOOP
0;JMP