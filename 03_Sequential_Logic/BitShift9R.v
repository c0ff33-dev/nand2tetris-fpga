/**
* 9 bit shift register (shifts to right)
* if      (load == 1)  out[t+1] = in[t]
* else if (shift == 1) out[t+1] = out[t]>>1 | (inMSB<<8)
* (shift one position to right and insert inMSB as most significant bit)
*/

`default_nettype none
module BitShift9R(
	input clk,
	input [8:0] in,
	input inMSB,
	input load,
	input shift,
	output reg [8:0] out
);

	// Put your code here:
	always @(posedge clk) begin
		if (load)
			out <= in;
		else if (shift)
			out <= (out >> 1) | (inMSB << 8);
	end

endmodule
