/**
* Data-Flip-Flop
* out[t+1] = in[t]
*/

`default_nettype none
module DFF(
		input clk,
		input in,
		output reg out = 0
);

	// No need to implement this chip
	// This module is implemented in verilog using reg-variables
	always @(posedge clk)
		if (in) out <= 1'b1;
		else out <= 1'b0;

endmodule

