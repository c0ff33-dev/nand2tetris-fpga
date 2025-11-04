// Attempt to trap RTP regardless of timing
// confirmed SDO/SCK ticking, SDI remains low
@LED
M=1
@R1
M=0
M=!M
D=M

(start)
@RTP
M=D // start RTP_SCK
@DEBUG4 // read RTP_SDI - now init/idle low?
// @DEBUG3 // read RTP_SDO - init low
// @DEBUG2 // read RTP_SCK - init low
D=M
@next // break if RTP is low
D;JEQ
@start // loop
0;JMP

(next)
@LED // LED=2
M=1
M=M+1

(start2)
@R1 // randomize RTP_SDO
D=!M
M=D
@RTP // start RTP_SCK
M=D
@DEBUG4 // read RTP_SDI
// @DEBUG3 // read RTP_SDO
// @DEBUG2 // read RTP_SCK
D=M-1
@end // break if RTP is high
D;JEQ
@start2 // loop
0;JMP

(end)
@LED // LED=3
M=1
M=M+1
M=M+1

(HALT) // trap
@HALT
0;JMP