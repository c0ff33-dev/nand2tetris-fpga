/**
 * 8-way Or: 
 * out = (in[0] or in[1] or ... or in[7])
 */

`default_nettype none
module Or8Way(
	input [7:0] in,
	output out
);

	assign out = |in; // reduction OR (in[0] or in[1] ... or in[7])

endmodule
