/**
* Uses CLK of 100MHz to generate:
* internal clock signal clk with 25MHz and
* a reset signal of approx. 20us length
*/
`default_nettype none
module Clock25_Reset20( 
    input CLK,			// external clock 100 MHz	
	output clk,			// internal clock 25 Mhz
	output reset 		// reset signal approx. 20us
);

	// scale down 100MHz to 25MHz (1/4)
	// 2 bits = 2^2 = 4 ticks x 2 per cycle = 2^3 for 4 cycles
	wire [15:0] psout;
	PC prescaler(.clk(CLK),.load(1'b0),.in(16'b0),.reset(1'b0),.inc(1'b1),.out(psout));
	Buffer clock(.in(psout[2]),.out(clk)); // demux the 3rd bit

	// TODO
	// assign reset = 1'b0;

endmodule
