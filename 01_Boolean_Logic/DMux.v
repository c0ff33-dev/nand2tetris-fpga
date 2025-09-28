/**
 * Demultiplexor:
 * {a, b} = {in, 0} if sel == 0
 *          {0, in} if sel == 1
 */

`default_nettype none
module DMux(
	input in,
	input sel,
    output a,
	output b
);

	// condition ? value_if_true : value_if_false
	assign a = (sel == 1'b0) ? in : 1'b0;
    assign b = (sel == 1'b1) ? in : 1'b0;

endmodule
