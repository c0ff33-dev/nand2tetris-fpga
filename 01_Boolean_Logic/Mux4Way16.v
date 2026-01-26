/**
 * 16 bit multiplexor: 
 * for i = 0..15 out[i] = a[i] if sel == 0 
 *                        b[i] if sel == 1
 */

`default_nettype none
module Mux4Way16(
	input [15:0] a,
	input [15:0] b,
	input [15:0] c,
	input [15:0] d,
   	input [1:0] sel,
	output [15:0] out
);
	
	// Put your code here:
	assign out = (sel == 2'b00) ? a :
			     (sel == 2'b01) ? b :
			     (sel == 2'b10) ? c :
			     d; // sel == 2'b11

endmodule
