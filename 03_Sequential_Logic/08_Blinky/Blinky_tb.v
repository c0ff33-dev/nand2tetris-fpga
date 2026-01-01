`default_nettype none
module Blinky_tb();

	// IN,OUT
	reg CLK=1;
	wire[1:0] LED;

	// Part
	Blinky blinky(
		.CLK(CLK),
		.LED(LED)
	);
	
	// Simulate
	always #1 CLK=~CLK; // no time scale

  	initial begin
  		$dumpfile("Blinky_tb.vcd");
  		$dumpvars(0, Blinky_tb);
		#100000
		$finish;
	end

endmodule
