/**
 * A 16-bit counter with load and reset control bits.
 * if      (reset[t] == 1) out[t+1] = 0
 * else if (load[t] == 1)  out[t+1] = in[t]
 * else if (inc[t] == 1)   out[t+1] = out[t] + 1  (integer addition)
 * else                    out[t+1] = out[t]
 */

`default_nettype none
module PC(
	input clk,
	input [15:0] in,
	input load,
	input inc,
	input reset,
	output [15:0] out
);	
	wire [15:0] next_out;

    // Compute next value of the counter
    assign next_out = reset ? 16'b0 :
                      load  ? in :
                      inc   ? (out + 1) :
                      out;

    Register register (
        .clk(clk),
        .in(next_out),
        .load(load | inc | reset),
        .out(out)
    );

endmodule
