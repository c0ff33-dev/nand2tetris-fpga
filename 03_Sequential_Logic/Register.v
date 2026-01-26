/**
 * 16 bit register:
 * If load[t] == 1 then out[t+1] = in[t]
 * else out does not change
 */

`default_nettype none
module Register(
	input clk,
	input [15:0] in,
	input load,
	output [15:0] out
);
    
    // Put your code here:
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : bit_array
            Bit bit (
                .clk(clk),
                .in(in[i]),
                .load(load),
                .out(out[i])
            );
        end
    endgenerate

endmodule
