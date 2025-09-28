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
	output reg out
);

	// Load new input value into the register on clock edge
	// else keep old value (no action needed)
	always @(posedge clk) begin
        if (load)
            out <= in;
    end

endmodule
