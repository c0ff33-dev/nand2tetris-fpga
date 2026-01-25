/**
 * The special function register RTP receives bytes from the touch panel
 * controller AR1021.
 * 
 * When load=1 transmission of byte in[7:0] is initiated. The byte is sent to
 * SDO bitwise together with 8 clock signals on SCK. At the same time RTP
 * receives a byte at SDI. During transmission out[15] is 1. The transmission
 * of a byte takes 256 clock cycles (32 cycles for each bit to achieve a slower
 * transfer rate). Every 32 clock cycles one bit is shifted out. In the middle
 * of each bit at counter number 31 the bit SDI is sampled. When transmission
 * is completed out[15]=0 and RTP outputs the received byte to out[7:0].
 *
 * AR1021 shifts on posedge, samples negedge (CPHA=0, CPOL=1) with a maximum
 * bit rate of ~900 KHz (~28 cycles @ 25 MHz clock) and requires an inter-byte delay
 * of ~50μs (1250 cycles) however this latter implementation detail is currently 
 * handled in software.
 */

`default_nettype none

module RTP(
	input clk,
	input load,
	input [15:0] in,
	output [15:0] out,
	output SDO,
	input SDI,
	output SCK
	// CSX is optional for AR1021
);
	
	// Note: current implementation passes sim but has not been tested on real hardware

	reg miso = 0;
	wire busy, reset, sckReset;
	wire [7:0] shiftOut;
	wire [15:0] busyCount, sckCount;

	// remaining registers are aligned to leading posedge (opposite of SPI)
	// so shift can happen first then sample later in same cycle
	// busy bit is set at load [t+1] regardless of in content

	// load on new byte or reset when complete
	// no CSX to manage so don't check in[8]
	Bit busyBit (
		.clk(clk),
		.in(reset ? 1'b0 : 1'b1),
		.load(load | reset),
		.out(busy)
	);

	// increment SCK while busy at 16 cycles per high/low
	// 1 cycle to set load, 32 cycles per bit
	// 256 cycles to shift 8 bits
	PC count_32(
		.clk(clk),
		.in(16'd0), // unused
		.load(1'd0), // unused
		.inc(busy), // inc while busy
		.reset(sckReset), // cycle 0 to max sckCount
		.out(sckCount)
	);
	assign sckReset = (sckCount == 16'd31);

	// reset busy signal after 256 cycles
	PC count_256(
		.clk(clk),
		.in(16'd0), // unused
		.load(1'd0), // unused
		.inc(busy), // inc while busy
		.reset(reset), // cycle 0 to max busyCount
		.out(busyCount)
	);
	assign reset = (busyCount == 16'd255);

	// MISO = SDI in [t+1]
	// sample during SCK negedge (but not too close to edge)
	// valid until following SCK negedge
	// must be negedge if sckCount==31 but this is probably
	// an artifact of tb using a posedge register for input
	always @(negedge clk)
		// wait at least 150ns after SCK low before sampling
		// anywhere along current SCK negedge will satisfy the sim
		if (sckCount==31)
			miso <= SDI;

	// circular buffer to enable duplex comms with slave where:
	// slave MSB >= master LSB (MISO)
	// master MSB >= slave LSB (MOSI)
	// init=0 before load, no shift on first cycle
	// shift late in SCK negedge so it emits posedge
	// valid until next posedge for sampling by AR1021
	BitShift8L shiftreg (
		.clk(~clk), // negate for posedge latch
		.in(init ? in[7:0] : 8'd0), // init on load
		.inLSB(init ? miso : 1'b0), // shift slaveMSB into masterLSB
		.load(init ? load : 1'b1), // don't shift on load
		.shift(sckCount==31), // shift once per 32 cycles
		.out(shiftOut) // available for sampling by negedge for SDO
	);

	// generic init handler, should work with ice40 + yosys
	reg init = 0;
	always @(posedge clk) begin
		if (~init) begin
			init <= 1;
		end
	end

	assign SDO = init ? (busy & shiftOut[7]) : 1'b0; // broadcast MOSI while busy
	assign SCK = init ? (busy & (sckCount <= 16'd15)) : 1'b0; // SCK high/low 16 cycles each
	assign out = init ? {busy,7'd0,shiftOut} : 16'd0; // out[15]=busy, out[7:0]=received byte

endmodule
