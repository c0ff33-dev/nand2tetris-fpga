/**
 * Not gate:
 * out = not in
 */

`default_nettype none
module Not(
	input in,
	output out
);

	// No need to implement this chip
	not(out,in);

endmodule
