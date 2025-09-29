/**
* Data-Flip-Flop
* out[t+1] = in[t]
*/

`default_nettype none
module DFF(
		input clk,
		input in,
		output reg out // probably expected to be able to redeclare as reg in body
);

	// No need to implement this chip
	// This chip is implemented in verilog using reg-variables
	always @(posedge clk) begin
		if (in) out <= 1'b1;
		else out <= 1'b0;
	end

endmodule
