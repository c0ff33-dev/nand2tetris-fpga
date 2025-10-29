/*
 * LCD communicates with ILI9341V LCD controller over 4 wire SPI.
 * 
 * When load=1 and in[8]=0 transmission of byte in[7:0] is initiated.
 * CSX is goes low (and stays low even when transmission is completed).
 * DCX is set to in[9]. The byte in[7:0] is send to SDO bitwise together
 * with 8 clock signals on SCK. During transmission out[15] is 1.
 * After 16 clock cycles transmission is completed and out[15] is set to 0.
 * 
 * When load=1 and in[8]=1 CSX goes high and DCX=in[9] without transmission
 * of any bit.
 * 
 * When load16=1 transmission of word in[15:0] is initiated. CSX goes low
 * (and stays low even when transmission is completed). DCX is set to 1 (data).
 * After 32 clock cycles transmission is completed and out[15] is set to 0.
 *
 * 240x320 display, 256K colours
 * DCX updates on the 7th negedge e.g. asserts on posedge of last command/data bit 
 * CSX must be driven low before 1st SCK posedge and high no earlier than 8th SCK negedge
*/
// sample posedge, shift negedge?
`default_nettype none
module LCD(
		input clk,			// clock 25 MHz
		input load,		    // start send command/byte over SPI
		input load16,		// start send data (16 bits)
		input [15:0] in,	// data to be sent
		output [15:0] out,	// data to be sent
		output DCX,			// SPI data/command not (0=command, 1=data)
		output CSX,			// SPI chip select not
		output SDO,			// SPI serial data out
		output SCK			// SPI serial clock
);

	wire csx, dcx, busy, busy16, reset;
	wire [7:0] shiftOut, shiftOut16;
	wire [15:0] clkCount;

	// if in[8=0] and load=1 then csx=0 (drive CSX low, send byte)
	// if in[8=1] and load=1 then csx=1 (drive CSX high without sending byte)
	// init csx=1 to block any premture transactions
	// csx remains unchanged in either case until next load
	Bit cs (
		.clk(clk),
		.in(init ? in[8] : 1'b1),
		.load(init ? load : 1'b1),
		.out(csx)
	);

	// TODO
	Bit dc (
		.clk(clk),
		.in(init ? in[8] : 1'b1),
		.load(init ? load : 1'b1),
		.out(dcx)
	);

	// remaining registers are aligned to leading negedge
	// so shift can happen first then sample later in same cycle
	// busy bit is still set at load [t+1]

	// if in[8=0] and load=1 then busy=1 (transmission in progress)
	// load on new byte or reset when complete
	Bit busyBit (
		.clk(~clk), // negedge
		.in(reset ? 1'b0 : ~in[8]),
		.load(load | reset),
		.out(busy)
	);

	Bit busy16Bit (
		.clk(~clk), // negedge
		.in(reset ? 1'b0 : ~in[8]),
		.load(load16 | reset16),
		.out(busy16)
	);
	
	// increment SCK while busy
	// 1 cycle to set load, 8 cycles to shift 8 bits
	PC count(
		.clk(~clk), // negedge
		.in(16'd0), // unused
		.load(1'd0), // unused
		.inc(busy | busy16), // inc while busy
		.reset(reset), // cycle 0 to max clkCount
		.out(clkCount)
	);
	assign reset = (clkCount == 16'd7);
	assign reset16 = (clkCount == 16'd15);

	// circular buffer to enable duplex comms with slave where:
	// slave MSB >= master LSB (MISO)
	// master MSB >= slave LSB (MOSI)
	// init=0 before load, no shift on first cycle

	// if load=1 shiftReg gets cycled through SDO
	// if load16=1 shiftReg gets cycled through shiftReg16
	BitShift8L shiftReg (
		.clk(clk), // negedge latch
		.in(init ? in[7:0] : 8'd0), // init on load
		.inLSB(1'b0), // no input, shiftReg will be empty after 8 cycles
		.load(init ? load : 1'b1), // don't shift on load
		.shift(busy | busy16), // shift continuously while sampling
		.out(shiftOut) // availble for sampling by posedge for SDO
	);

	// if load=1 shiftReg16 is ignored
	// if load16=1 shiftReg16 gets cycled through SDO
	//   and then after 8 cycles it will be where shiftReg started
	BitShift8L shiftReg16 (
		.clk(clk), // negedge latch
		.in(init ? in[15:8] : 8'd0), // init on load
		.inLSB(init ? shiftOut[7] : 1'b0), // shift slaveMSB into masterLSB
		.load(init ? load16 : 1'b1), // don't shift on load
		.shift(busy16), // shift continuously while sampling
		.out(shiftOut16) // availble for sampling by posedge for SDO
	);

	// generic init handler, should work with ice40 + yosys
	reg init = 0;
	always @(posedge clk) begin
		if (~init) begin
			init <= 1;
		end
	end

	assign CSX = init ? (load ? 1'b0 : csx) : 1'b1; // init CSX=1, drive low on load (CS setup time)
	assign SDO = init ? (busy16 ? (busy & shiftOut16[7]) : (busy & shiftOut[7])) : 1'b0; // MOSI (masterMSB to slaveLSB)
	assign SCK = init ? ((busy | busy16) & clk) : 1'b0; // run SCK while busy, start low
	assign DCX = init ? (dcx) : 1'b0; // TODO
	assign out = init ? (busy16 ? {busy,shiftOut16[14:0]} : {busy,7'd0,shiftOut}) : 16'd0; // out[15]=busy, out[7:0]=received byte

endmodule
