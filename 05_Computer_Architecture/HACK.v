/**
 * The HACK computer, including CPU, ROM, RAM and the generator for
 * reset and clk (25MHz) signal. For approx. 20us HACK CPU resets.
 * From this point onward the user is at the mercy of the software.
 * In particular, depending on the program's code, the LED may show
 * some output and the user may be able to interact with the computer
 * via the BUT.
 */

`default_nettype none
module HACK( 
    input CLK,			// external clock 100 MHz	
	input [1:0] BUT,	// user button (0 if pressed, 1 if released)
	output [1:0] LED	// leds (0 off, 1 on)
);

	wire RST,clk,writeM,loadRAM;
	wire loadIO0,loadIO1,loadIO2,loadIO3,loadIO4,loadIO5,loadIO6,loadIO7;
	wire loadIO8,loadIO9,loadIOA,loadIOB,loadIOC,loadIOD,loadIOE,loadIOF;
	wire [15:0] inIO1,inIO2,inIO3,inIO4,inIO5,inIO6,inIO7,inIO8;
	wire [15:0] inIO9,inIOA,inIOB,inIOC,inIOD,inIOE,inIOF,outLED,outRAM;
	wire [15:0] addressM,pc,outM,inM,instruction;

	// 25 MHz internal clock w/ 20us initial reset period
	Clock25_Reset20 clock(.CLK(CLK),.clk(clk),.reset(RST));

	// CPU (ALU, A, D, PC)
	CPU cpu(.clk(clk),.inM(inM),.instruction(instruction),.reset(RST),.outM(outM),.writeM(writeM),.addressM(addressM),.pc(pc));

	// Memory (map only)
	Memory mem(
		.address(addressM),
		.load(writeM),
		.inRAM(outRAM), // RAM (0-3839)
		.inIO0(outLED), // LED (4096)
		.inIO1(inIO1), // BUT2 (4097)
		.inIO2(inIO2), // reserved [15:0]
		.inIO3(inIO3), // reserved [15:0]
		.inIO4(inIO4), // reserved [15:0]
		.inIO5(inIO5), // reserved [15:0]
		.inIO6(inIO6), // reserved [15:0]
		.inIO7(inIO7), // reserved [15:0]
		.inIO8(inIO8), // reserved [15:0]
		.inIO9(inIO9), // reserved [15:0]
		.inIOA(inIOA), // reserved [15:0]
		.inIOB(inIOB), // DEBUG0 (4107)
		.inIOC(inIOC), // DEBUG1 (4108)
		.inIOD(inIOD), // DEBUG2 (4109)
		.inIOE(inIOE), // DEBUG3 (4110)
		.inIOF(inIOF), // DEBUG4 (4111)
		.out(inM),
		.loadRAM(loadRAM),
		.loadIO0(loadIO0), // LED
		.loadIO1(loadIO1), // BUT
		.loadIO2(loadIO2), // reserved
		.loadIO3(loadIO3), // reserved
		.loadIO4(loadIO4), // reserved
		.loadIO5(loadIO5), // reserved
		.loadIO6(loadIO6), // reserved
		.loadIO7(loadIO7), // reserved
		.loadIO8(loadIO8), // reserved
		.loadIO9(loadIO9), // reserved
		.loadIOA(loadIOA), // reserved
		.loadIOB(loadIOB), // DEBUG0
		.loadIOC(loadIOC), // DEBUG1
		.loadIOD(loadIOD), // DEBUG2
		.loadIOE(loadIOE), // DEBUG3
		.loadIOF(loadIOF)  // DEBUG4
	);

	// ROM (simulated), 256 x 16 bit words
	ROM rom(.pc(pc),.instruction(instruction));

	// BRAM (0-3839 x 16 bit words)
	RAM3840 ram(
		.clk(clk),
		.address(addressM[11:0]),
		.in(outM),
		.load(loadRAM),
		.out(outRAM)
	);

	// LED (4096)
	Register led(
		.clk(clk),
		.in(outM),
		.load(loadIO0),
		.out(outLED)
	);
	assign LED = outLED[1:0];

	// BUT2 (4097)
	Register but(
		.clk(clk),
		.in({14'd0, BUT}), // concat 14 bits for padding
		.load(1'b1),
		.out(inIO1)
	);

	// DEBUG0 (4107)
	Register debug0(
		.clk(clk),
		.in(outM),
		.load(loadIOB),
		.out(inIOB)
	);

	// DEBUG1 (4108)
	Register debug1(
		.clk(clk),
		.in(outM),
		.load(loadIOC),
		.out(inIOC)
	);

	// DEBUG2 (4109)
	Register debug2(
		.clk(clk),
		.in(outM),
		.load(loadIOD),
		.out(inIOD)
	);

	// DEBUG3 (4110)
	Register debug3(
		.clk(clk),
		.in(outM),
		.load(loadIOE),
		.out(inIOE)
	);

	// DEBUG4 (4111)
	Register debug4(
		.clk(clk),
		.in(outM),
		.load(loadIOF),
		.out(inIOF)
	);

endmodule
