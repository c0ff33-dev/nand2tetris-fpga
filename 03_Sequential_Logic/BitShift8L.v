/**
* 8 bit shift register (shifts to left)
* if      (load == 1)  out[t+1] = in[t]
* else if (shift == 1) out[t+1] = out[t]<<1 | inLSB
* (shift one position to left and insert inLSB as least significant bit)
*/

`default_nettype none
module BitShift8L(
	input clk,
	input [7:0] in,
	input inLSB,
	input load,
	input shift,
	output reg [7:0] out
);

	// Put your code here:
	// See SPI for timing explanation
	always @(negedge clk) begin
		if (load)
			out <= in;
		else if (shift)
			out <= (out << 1) | {7'b0, inLSB};
	end

endmodule
