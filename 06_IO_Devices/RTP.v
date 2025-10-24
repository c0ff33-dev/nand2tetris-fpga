/**
 * The special function register RTP receives bytes from the touch panel
 * controller AR1021.
 * 
 * When load=1 transmission of byte in[7:0] is initiated. The byte is send to
 * SDO bitwise together with 8 clock signals on SCK. At the same time RTP
 * receives a byte at SDI. During transmission out[15] is 1. The transmission
 * of a byte takes 256 clock cycles (32 cycles for each bit to achieve a slower
 * transfer rate). Every 32 clock cycles one bit is shifted out. In the middle
 * of each bit at counter number 31 the bit SDI is sampled. When transmission
 * is completed out[15]=0 and RTP outputs the received byte to out[7:0].
 */

 // Might have damaged AR1021 VDD/M1 trace :(
 // Tested ground & M1 in continuity mode = infinite resistance (0=short, 100k=resistor)

 // Relevant docs start at page 18
 // IRQ not used? should start IRQ/SCK low, IRQ high [t], SCK/SDO high [t+1]
 // returns 0x4D if read when no data to return
 // AR1021 shifts posedge/cycle boundary, samples middle/negedge (CPHA=0, CPOL=1)
 // ~900kHz (~28 cycles) max bit rate w/ inter-byte delay of ~50μs (1250 cycles)
 // min 550ns (~14 cycles) from CSX low to SCK high, min 800ns (~20 cycles) from last SCK low to CSX high
 // min 100ns (~3 cycles) SDI setup before SCK low & hold after SCK low
 // SDO valid for max 150ns (3-4 cycles) after SCK low, max 50ns (~1 cycle) for SDO rise/fall
 // touch report = SDO: PEN, X_lo, X_hi, Y_lo, T_hi (5 bytes)
 //  PEN [7:0]: 1------P, P=0/1 pen up/down
 // X_lo [7:0]: 0XXXXXXX, X6-X0
 // X_hi [7:0]: 000XXXXX, X11-X7
 // Y_lo [7:0]: 0YYYYYYY, X6-X0
 // Y_hi [7:0]: 000YYYYY, X11-X7
 // command format: header, size, data, ... // size = bytes after this byte
 // response: header, size, status, command, data, ...
 // status: 0x00 success, 0x01 bad command, 0x03 bad header, 0x04 timeout, 0xFC cancel calibration
 // ENABLE_TOUCH = 0x55, 0x01, 0x12 // response = 0x55, 0x02, 0x00, 0x12
 // DISABLE_TOUCH = 0x55, 0x01, 0x13 // response = 0x55, 0x02, 0x00, 0x13
 // recommended to send DISABLE_TOUCH and wait 50ms before sending commands

`default_nettype none

module RTP(
	input clk,
	input load,
	input [15:0] in,
	output [15:0] out,
	output SDO,
	input SDI,
	output SCK
);

	// Put your code here:

endmodule
