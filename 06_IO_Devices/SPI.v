/**
 * SPI controller for W25Q16BV (flash ROM)
 * 
 * When load=1 transmission of byte in[7:0] is initiated. The byte is sent to
 * MOSI (master out slave in) bitwise together with 8 clock signals on SCK.
 * At the same time the SPI recieves a byte at MISO (master in slave out).
 * Sampling of MISO is done at posedge of SCK and shifting is done at
 * negative edge.
 * 
 * For W25Q16BV the command & address bytes are latched on posedge of SCK
 * but CSX must be driven low at least 5ns before the first SCK posedge. The data 
 * returned by the command is shifted to MISO on the negedge of SCK and increments
 * address automatically on the completion of each byte until CSX is driven high.
 * 
 * https://en.wikipedia.org/wiki/Serial_Peripheral_Interface
 */ 

`default_nettype none
module SPI(
	input clk,
	input CDONE, // configuration done (ice40 only)
	input load,
	input SDI, // serial data in (MISO)
	input [15:0] in, // [7:0] byte to send (address/command)
	output SCK, // serial clock
	output CSX, // chip select not (active low)
	output SDO, // serial data out (MOSI)
	output [15:0] out // out[15]=1 if busy, out[7:0] received byte
);
	reg miso = 0;
	wire csx, busy, reset;
	wire [7:0] shiftOut;
	wire [15:0] clkCount;
	
	// if in[8=0] and load=1 then csx=0 (send byte)
	// if in[8=1] and load=1 then csx=1 (drive CSX high without sending byte)
	// init csx=1 to block any premture transactions
	// csx remains unchanged in either case until next load
	Bit cs (
		.clk(clk),
		.in(init ? in[8] : 1'b1),
		.load(init ? load : 1'b1),
		.out(csx)
	);

	// if in[8=0] and load=1 then busy=1 (transmission in progress)
	// load on new byte or reset when complete
	Bit busyBit (
		.clk(clk),
		.in(reset ? 1'b0 : ~in[8]),
		.load(load | reset),
		.out(busy)
	);

	// increment SCK while busy
	// 1 cycle to set load, 8 cycles to shift 8 bits
	PC count(
		.clk(clk),
		.in(16'd0), // unused
		.load(1'd0), // unused
		.inc(busy), // inc while busy
		.reset(reset), // cycle 0 to max clkCount
		.out(clkCount)
	);
	assign reset = (clkCount == 16'd7);

	// MISO = SDI in [t+1]
	// sample on posedge SCK
	always @(posedge SCK)
		miso <= SDI;

	// this timing is very sensitive at 8 cycles/byte
	// in practice as long as SDO has the right bit
	// before SCK rising edge it should work out

	// circular buffer to enable duplex comms with slave where:
	// slave MSB >= master LSB (MISO)
	// master MSB >= slave LSB (MOSI)
	// init=0 before load, no shift on first cycle
	BitShift8L shiftreg (
		.clk(clk), // needs to be on clk domain for load
		.in(init ? in[7:0] : 8'd0), // init on load (combinational input from CPU)
		.inLSB(init ? miso : 1'b0), // shift slaveMSB into masterLSB while sampling
		.load(init ? load : 1'b1), // don't shift on load
		.shift(SCK & busy), // shift MISO from [t-1] through in [t+1]
		.out(shiftOut) // input value latched on rising edge, shifted out on falling edge
	);

	// generic init handler, should work with ice40 + yosys
	reg init = 0;
	always @(posedge clk) begin
		if (!init) begin
			init <= 1;
		end
	end

	assign CSX = (init & CDONE) ? (load ? 1'b0 : csx) : 1'b1; // init CSX=1, drive low on load (CS setup time)
	assign SDO = shiftOut[7] & busy; // MOSI (masterMSB to slaveLSB)
	assign SCK = init ? (busy & ~clk) : 1'b0; // run SCK while busy, start low
	assign out = {busy,7'd0,shiftOut}; // out[15]=busy, out[7:0]=received byte

endmodule
