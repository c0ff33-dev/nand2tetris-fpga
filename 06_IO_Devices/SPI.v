/**
 * SPI controller for W25Q16BV
 * 
 * When load=1 transmission of byte in[7:0] is initiated. The byte is sent to
 * MOSI (master out slave in) bitwise together with 8 clock signals on SCK.
 * At the same time the SPI recieves a byte at MISO (master in slave out).
 * Sampling of MISO is done at posedge of SCK and shifting is done at
 * negative edge.
 *
 * More helpful diagrams @ https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
 */ 

// TODO: out emitted after first load with no prior busy?

`default_nettype none
module SPI(
	input clk,
	input CDONE, // configuration done (ice40 only)
	input load,
	input SDI, // serial data in (MISO) -- HACK block diagram is wrong direction
	input [15:0] in, // [7:0] byte to send (address/command)
	output SCK, // serial clock
	output CSX, // chip select not (active low)
	output SDO, // serial data out (MOSI) -- HACK block diagram is wrong direction
	output [15:0] out // out[15]=1 if busy, out[7:0] received byte
);
	reg mosi = 0;
	wire csx, busy, reset, slaveMSB;
	wire [7:0] shift;
	wire [15:0] clkCount;
	// reg [15:0] inReg;
	// assign SDO = inReg[15]; // MSB first?

	// if in[8=0] and load=1 then csx=0 (send byte)
	// if in[8=1] and load=1 then csx=1 (don't send byte)
	// init csx=1 to block any premture transactions
	// csx remains unchanged in either case until next load
	Bit cs (
		.clk(clk),
		.in(init ? in[8] : 1'b1),
		.load(init ? load : 1'b1),
		.out(csx)
	);

	// if in[8=0] and load=1 then busy=1 (transmission in progress)
	// load on new byte or reset after 8 clock cycles
	Bit busyBit (
		.clk(clk),
		.in(reset ? 1'b0 : ~in[8]),
		.load(load | reset),
		.out(busy)
	);

	// count cycles while busy
	PC count(
		.clk(clk),
		.in(16'd0), // unused
		.load(1'd0), // unused
		.inc(busy), // inc while busy
		.reset(reset), // unused // TODO: shouldn't this reset after 8 clock cycles?
		.out(clkCount)
	);

	assign reset = (clkCount == 16'd15);
	// always @(posedge clk) begin
	// 	if (clkCount == 16'd7)
	// 		reset <= 1; 
	// 	else
	// 		reset <= 0;
	// end

	// save in for transmission in [t+1]
	// always @(posedge clk) begin
	// 	if (load)
	// 		inReg <= in;
	// end

	// circular buffer to enable duplex comms with slave where:
	// slave MSB >= master LSB (MISO)
	// master MSB >= slave LSB (MOSI)
	// dual clock edge == read-before-write pattern?
	Bit miso (
		.clk(clk), // sample SDI at posedge of clk
		.in(SDI), // MISO (MSB from slave)
		.load(busy), // sample for [t+8] after load
		.out(slaveMSB)
	);
	BitShift8L shiftreg (
		.clk(~SCK), // sample on negedge of SCK (posedge clk)
		.in(8'd0), // init on load
		.inLSB(init ? slaveMSB : 1'b0), // shift slaveMSB into masterLSB while sampling
		.load(init ? load : 1'b1), // don't shift on load
		.shift(busy), // shift at negedge for [t+8] after load
		.out(shift) // master byte
	);
	always @(posedge clk) begin
		mosi <= shift[7]; // MSB first
	end

	// generic init handler, should work with ice40 + yosys
	reg init = 0;
	always @(posedge clk) begin
		if (!init) begin
			init <= 1;
		end
	end

	assign CSX = (init & CDONE) ? csx : 1'b1; // init CSX=1 as well
	assign SDO = mosi; // MOSI (masterMSB to slaveLSB)
	assign SCK = init ? (busy & clkCount[0]) : 1'b0; // run SCK while busy, half speed // TODO: why half speed?
	assign out = {busy,7'd0,shift};

endmodule
