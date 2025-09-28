/**
 * Not gate:
 * out = not in
 */

`default_nettype none
module Not(
	input in,
	output out
);

	not(out,in); // verilog primitive

endmodule
