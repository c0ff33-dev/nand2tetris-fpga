/**
 * 16 bit incrementer:
 * out = in + 1 (arithmetic addition)
 */

`default_nettype none
module Inc16(
	input [15:0] in,
	output [15:0] out
);

	assign out = in + 1;

endmodule
