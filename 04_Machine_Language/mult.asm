// mult.asm
// calculate R2 = R0 * R1
// and check the result.

// Load test data: R0=13, R1=55
// and set LED=1
@13
D=A
@R0
M=D // R0 (num1) = 13

@55
D=A
@R1
M=D // R1 (num2) = 55

@LED // likely not visible on hardware unless really clocked down
M=2 // LED=2 (10 = LED1 on/LED2 off, program has started)

// Put your code here:

// sum += num1
// loop num2 times
// R0 = num1, R1 = num2, R2 = sum, R3 = i

// init vars
@R3
M=0 // i = 0
@R2
M=0 // sum = 0

(LOOP)
@R3
D=M // D = i
@R1
D=D-M // D = i - num2
@BREAK
D;JGE // break if i > num2

// else sum += num1, i++
@R0
D=M // D = num1
@R2
M=D+M // sum += num1
@R3
M=M+1 // i++

// return to top of loop
@LOOP
0;JMP

(BREAK)

// till here!

// Check result according to
// LED = 1 (correct result)
// LED = 3 (wrong result)
// and HALT
@R2
D=M // D = sum
@715
D=D-A // D = sum - 715
@OK
D;JEQ // OK if R2 == 715

// ERROR
@3
D=A // D=3
@LED
M=D // LED=3 (11 = LED1/2 on, error)
@HALT
0;JMP // end

(OK)
@2
D=A // D = 2
@LED
M=D // LED=1 (01 = LED1 off/LED2 on, success)

(HALT)
@HALT
0;JMP // end
