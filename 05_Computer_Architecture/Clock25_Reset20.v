/**
* Uses CLK of 100MHz to generate:
* internal clock signal clk with 25MHz and
* a reset signal of ~20us duration
*/
`default_nettype none
module Clock25_Reset20( 
    input CLK,			// external clock 100 MHz	
	output clk,			// internal clock 25 Mhz
	output reset 		// reset signal ~20us
);

	// assign CLK to a counter
	wire [15:0] psout;
	PC prescaler(.clk(CLK),.load(1'b0),.in(16'b0),.reset(1'b0),.inc(1'b1),.out(psout));
	
	// scale down 100MHz to 25MHz (1/4)
	// 2 bits = 2^2 = 4 ticks x 2 per cycle = 2^3 for 4 cycles
	Buffer clock(.in(psout[2]),.out(clk)); // demux the 3rd bit
	
	// Reset high for first 20us @ 100 MHz
	// 1 cycle = 100 million / second or 10ns (ns = 1 billion / second)
	// 1000ns = 1 us (microsecond = 1 million / second)
	// therefore 20us = 20 x 1000 / 10 = 2000 cycles
    assign reset = (psout <= 16'd2000);

endmodule
