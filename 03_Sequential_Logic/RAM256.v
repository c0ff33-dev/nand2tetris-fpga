/**
* RAM256 implements 256 words of RAM addressed from 0-255
* out = M[address]
* if (load =i= 1) M[address][t+1] = in[t]
*/

`default_nettype none
module RAM256(
	input clk,
	input [7:0] address,
	input [15:0] in,
	input load,
	output reg [15:0] out
);
	
	// No need to implement this chip
	// RAM is implemented using BRAM of iCE40
	reg [15:0] regRAM [0:255];

	// Note: HACK requires read-before-write / READ_FIRST behaviour, e.g. M=M+1:
	// - current regRAM[address] is read in from [t-1]
	// - expression result (in) is combinationally eval'd [t]
	// - write new regRAM[address] (out) at [t+1]

	// Syncronized dual port pattern - only this specific wave pattern works
	always @(posedge clk) begin
		// in is sampled on posedge [t]
		// but won't be written to regRAM[address] until [t+1]
		if (load) regRAM[address[7:0]] <= in;
	end

	// Note: Timing changes here also need to propogate to ROM chip + RAM/ROM test benches.

	// new code: explicit syncronous read - its very likely the synthesis result for the 
	// original code was also inferring syncronous negedge read with the iCE40 BRAM primitives
	always @(negedge clk) begin
		// out is sampled on negedge [t]
		// emits the value of regRAM[address] from [t-1]
		// memory values are undefined until written to for the first time
		out <= regRAM[address[7:0]];
	end

	// original code: continous/combinational read (not supported in BRAM)
	// assign out = regRAM[address[7:0]];

endmodule
