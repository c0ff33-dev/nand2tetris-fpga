/**
 * Exclusive-or gate:
 * out = not (a == b)
 */

`default_nettype none
module Xor(
	input a,
	input b,
	output out
);

	xor(out,a,b); // bitwise XOR (verilog primitive)

endmodule
