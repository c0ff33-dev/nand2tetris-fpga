/**
 * The HACK computer, including CPU, ROM, RAM and the generator for
 * reset and clk (25 MHz) signal. For ~20μs HACK CPU resets.
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

	// Put your code here:
	wire RST,clk,writeM,loadRAM,resLoad;
	wire loadIO0,loadIO1,loadIOB,loadIOC,loadIOD,loadIOE,loadIOF;
	wire [15:0] inIO1,inIOB,inIOC,inIOD,inIOE,inIOF,outLED,outRAM;
	wire [15:0] addressM,pc,outM,inM,instruction,resIn;

	// 25 MHz internal clock w/ 20μs initial reset period
	Clock25_Reset20 clock(
		.CLK(CLK),
		.clk(clk),
		.reset(RST)
	);

	// CPU (ALU, A, D, PC)
	CPU cpu(
		.clk(clk),
		.inM(inM),
		.instruction(instruction),
		.reset(RST),
		.outM(outM),
		.writeM(writeM),
		.addressM(addressM),
		.pc(pc)
	);

	// Memory (map only)
	Memory mem(
		.address(addressM),
		.load(writeM),
		.inRAM(outRAM),// RAM (0-3583)
		.inIO0(outLED),// LED (4096)
		.inIO1(inIO1), // BUT (4097)
		.inIO2(resIn), // reserved (undefined)
		.inIO3(resIn), // reserved (undefined)
		.inIO4(resIn), // reserved (undefined)
		.inIO5(resIn), // reserved (undefined)
		.inIO6(resIn), // reserved (undefined)
		.inIO7(resIn), // reserved (undefined)
		.inIO8(resIn), // reserved (undefined)
		.inIO9(resIn), // reserved (undefined)
		.inIOA(resIn), // reserved (undefined)
		.inIOB(inIOB), // DEBUG0 (4107)
		.inIOC(inIOC), // DEBUG1 (4108)
		.inIOD(inIOD), // DEBUG2 (4109)
		.inIOE(inIOE), // DEBUG3 (4110)
		.inIOF(inIOF), // DEBUG4 (4111)
		.out(inM),
		.loadRAM(loadRAM), // RAM (0-3583)
		.loadIO0(loadIO0), // LED (4096)
		.loadIO1(loadIO1), // BUT (4097)
		.loadIO2(resLoad), // reserved (undefined)
		.loadIO3(resLoad), // reserved (undefined)
		.loadIO4(resLoad), // reserved (undefined)
		.loadIO5(resLoad), // reserved (undefined)
		.loadIO6(resLoad), // reserved (undefined)
		.loadIO7(resLoad), // reserved (undefined)
		.loadIO8(resLoad), // reserved (undefined)
		.loadIO9(resLoad), // reserved (undefined)
		.loadIOA(resLoad), // reserved (undefined)
		.loadIOB(loadIOB), // DEBUG0 (4107)
		.loadIOC(loadIOC), // DEBUG1 (4108)
		.loadIOD(loadIOD), // DEBUG2 (4109)
		.loadIOE(loadIOE), // DEBUG3 (4110)
		.loadIOF(loadIOF)  // DEBUG4 (4111)
	);

	// ROM (simulated), 256 x 16 bit words
	ROM rom(
		.clk(clk),
		.pc(pc),
		.instruction(instruction)
	);

	// BRAM (0-3583 x 16 bit words)
	RAM3584 ram(
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

	// BUT (4097)
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
