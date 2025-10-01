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
	reg [15:0] regRAM [0:255]; 
	always @(posedge clk) begin
		if (load) regRAM[address[7:0]] <= in;

		// new code: syncronous read (needs to be typed as register)
		// Note: this is implicit read-before-write, e.g. M=M+1:
		// - current regRAM[address] is read in [t-1]
		// - expression result (in) is eval'd in the same cycle [t] (combinational)
		// - write new regRAM[address] (out) and A register simultaneously at conclusion of the block [t+1]
		out <= regRAM[address[7:0]];
	end

	// original code: async read - this is unstable at 100 MHz on
	// hardware but not in simulation so likely BRAM latency issue
	// assign out = regRAM[address[7:0]];

endmodule
