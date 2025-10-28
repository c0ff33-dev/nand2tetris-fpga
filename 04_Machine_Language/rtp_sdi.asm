// Attempt to trap SDI regardless of timing
@LED
M=1

(start)
@RTP // start RTP_SCK
M=0  
@DEBUG4 // read RTP_SDI
D=M  
@end // break if SDI is ever low
D;JEQ
@start // loop
0;JMP

(end)
@LED // LED=3
M=1
M=M+1
M=M+1

(HALT) // trap
@HALT
0;JMP