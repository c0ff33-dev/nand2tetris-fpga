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
	// - write new regRAM[address] (out) and A register simultaneously at conclusion of the block [t+1]

	// Dual port pattern required at 100 MHz
	// Additionally only this specific clock assignment for read/write works on hardware
	// No permutation of assignments worked in same clock domain for single port
	assign wclk = clk;
	always @(posedge wclk) begin
		if (load) regRAM[address[7:0]] <= in;
	end

	assign rclk = ~clk;
	always @(posedge rclk) begin
		out <= regRAM[address[7:0]];
	end

	// original code: async read - this is unstable at 100 MHz on
	// hardware but not in simulation so likely BRAM latency issue
	// assign out = regRAM[address[7:0]];

endmodule
