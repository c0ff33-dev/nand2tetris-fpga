/**
* RAM256 implements 256 Bytes of RAM addressed from 0 - 255
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
	wire rclk;
	wire wclk;
	reg [15:0] regRAM [0:255];

	// new code: syncronous read (needs to be typed as register)
	// Note: HACK requires read-before-write behaviour, e.g. M=M+1:
	// - current regRAM[address] is read in [t-1]
	// - expression result (in) is eval'd in the same cycle [t] (combinational)
	// - write new regRAM[address] (out) at conclusion of the block [t+1]

	// Syncronized dual port pattern - only this specific wave pattern works (READ_FIRST)
	always @(posedge clk) begin
		// write scheduled during rising edge but don't express until [t+1]
		if (load) regRAM[address[7:0]] <= in;
	end

	always @(negedge clk) begin
		// read out [t-1] during falling edge but don't express until [t+1]
		// DFF polls for updates at the following rising edge
		out <= regRAM[address[7:0]];
	end

	// original code: continous/combinational read
	// assign out = regRAM[address[7:0]];

endmodule
