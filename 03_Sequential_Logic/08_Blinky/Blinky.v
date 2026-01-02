// Test to run on fpga with 100 MHz

`default_nettype none
module Blinky(
	input CLK,
	output [1:0] LED
);

	// 100 MHz clock updating Buffer every time the 13th bit cycles or 2^12 bits,
	// but it's only updated on the posedge so its 2^13 = 8192 cycles.
	// 100 MHz / 8192 = 12.2 KHz pre-scaled clock
	wire [15:0] prescaler;
	wire clk;
	PC PRESCALER(.clk(CLK),.load(1'b0),.in(16'b0),.reset(1'b0),.inc(1'b1),.out(prescaler));
	Buffer 	CLOCK(.in(prescaler[12]),.out(clk));

	// Subdivided even further by the next counter: 
	// 12.2 KHz / 2^14 = 0.74 Hz blink rate
	// 12.2 KHz / 2^15 = 0.37 Hz blink rate

	// The offset timing gives the oscillating pattern of:
	// - LED1/2 off
	// - LED1 on, LED2 off
	// - LED1 off, LED2 on, 
	// - LED1/2 on
	wire [15:0] counter;
	PC COUNTER(.clk(clk),.load(1'b0),.in(16'b0),.reset(1'b0),.inc(1'b1),.out(counter));
	Buffer BUF1(.in(counter[15]),.out(LED[1]));
	Buffer BUF2(.in(counter[14]),.out(LED[0]));

endmodule
