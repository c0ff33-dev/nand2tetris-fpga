// memory.asm
// test consecutive memory read/writes
// no need to implement this program / for debugging purposes only

@1
D=A
@LED
M=D // LED=1 (01 = LED1 on/LED2 off, program has started)

@0
M=A // RAM[0] = 0 (init)
M=M+1 // RAM[0]++
M=M+1
M=M+1
M=M+1
M=M+1
M=M+1
M=M+1
M=M+1
M=M+1
M=M+1 // RAM[0] = 10

// Check result and HALT
D=M // D = RAM[0] (result)
@10 // (expected)
D=D-A // D = result - expected
@OK
D;JEQ // OK if result == expected

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
M=D // LED=2 (10 = LED1 off/LED2 on, success)

(HALT)
@HALT
0;JMP // end
