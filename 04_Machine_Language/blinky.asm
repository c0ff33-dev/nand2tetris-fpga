// Fast blink for checking real-time signals etc
// Max perceptible blink rate is ~25 Hz
@LED
M=1

(start)
@75 // lower = faster
D=A
@R0
M=D

(out_loop)
@32767
D=A
@in_loop
(in_loop)
D=D-1
D;JNE // --i

@R0
D=M
M=M-1
@out_loop
D;JNE // --j

// wire signal
// @RTP
// D=M

// debug signal
// @1
// D=A

// known bugs:
// M+D doesn't assemble

@LED
M=M+1

@start
0;JMP