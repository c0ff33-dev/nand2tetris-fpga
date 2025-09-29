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
	output out // consumers of the DFF can use a wire though
);

	wire dff_in;
    wire dff_out;

    // Multiplexer for load functionality:
    // If load=1, feed 'in' to DFF,
	// else feed previous output to DFF to hold state
    assign dff_in = load ? in : dff_out;

    DFF dff (
        .clk(clk),
        .in(dff_in),
        .out(dff_out)
    );

endmodule
