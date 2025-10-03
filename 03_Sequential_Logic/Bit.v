/**
 * 1-bit register:
 * If load[t] == 1 then out[t+1] = in[t]
 *    else out does not change (out[t+1] = out[t])
 */

`default_nettype none
module Bit(
	input clk,
	input in,
	input load,
	output out
);

	// Multiplexer for load functionality:
    // If load=1, feed 'in' to DFF,
	// else feed previous output to DFF to hold state
    DFF dff (
        .clk(clk),
        .in(load ? in : out),
        .out(out)
    );

endmodule
