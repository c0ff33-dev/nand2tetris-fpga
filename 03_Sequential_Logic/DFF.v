/**
* Data-Flip-Flop
* out[t+1] = in[t]
*/

`default_nettype none
module DFF(
		input clk,
		input in,
		output out
);

	reg _out;

	// No need to implement this chip
	// This chip is implemented in verilog using reg-variables
	always @(posedge clk) begin
		if (in) _out <= 1'b1;
		else _out <= 1'b0;
	end
	
	assign out = _out;

endmodule
