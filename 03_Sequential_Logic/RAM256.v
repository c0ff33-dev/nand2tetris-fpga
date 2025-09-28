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
	output [15:0] out
);
	
	// No need to implement this chip
	// RAM is implemented using BRAM of iCE40
	reg [15:0] regRAM [0:255]; 
	always @(posedge clk)
		if (load) regRAM[address[7:0]] <= in;

		// TODO: Run some tests with concurrent read/write
		// docs don't specify read-first/write-first when using inferred BRAM
		// M=M+1 or similar requires read-first

		// proposed code: sync read (needs to be typed as register)
		// out <= regRAM[address[7:0]];

	// original code: async read
	// this feels like a hack to try and force read-first but BRAM is intended to have sync read
	assign out = regRAM[address[7:0]];

endmodule
