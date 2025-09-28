/**
 * Computes the sum of three bits.
 */

`default_nettype none
module FullAdder(
	input a,		// 1-bit input
	input b,		// 1-bit input
	input c,		// 1-bit input
	output sum,		// Right bit of a + b + c
	output carry	// Left bit of a + b + c
);

	assign sum  = a ^ b ^ c;
	assign carry = (a & b) | (b & c) | (a & c);

endmodule
