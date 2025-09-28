/**
* 8-bit Shiftregister (shifts to left)
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
	output [7:0] out
);
	reg [7:0] _out;

	always @(posedge clk) begin
		if (load)
			_out <= in;
		else if (shift)
			_out <= (_out << 1) | {7'b0, inLSB};
	end

	assign out = _out;

endmodule
