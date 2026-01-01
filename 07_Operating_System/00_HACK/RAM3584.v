/**
* RAM3584 implements 3584 words of RAM addressed from 0-3583
* Originally designed for 3584 words addressed from 0-3839 but insufficient BEL/LCs on iCE40
* out = M[address]
* if (load =i= 1) M[address][t+1] = in[t]
*/

`default_nettype none
module RAM3584(
	input clk,
	input [11:0] address,
	input [15:0] in,
	input load,
	output [15:0] out
);
	
	// No need to implement this chip
	// RAM is implemented using BRAM of iCE40
	reg [15:0] regRAM [0:3583]; 
	always @(posedge clk)
		if (load) regRAM[address[11:0]] <= in;

	assign out = regRAM[address[11:0]];

endmodule
