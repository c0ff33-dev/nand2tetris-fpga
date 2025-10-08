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

`default_nettype none
module SPI(
	input clk,
	input load,
	input SDI, // serial data in (MISO) -- HACK block diagram is wrong
	input [15:0] in, // [7:0] byte to send (address/command)
	output CSX, // chip select not (active low)
	output SDO, // serial data out (MOSI) -- HACK block diagram is wrong
	output SCK, // serial clock
	output [15:0] out // out[15]=1 if busy, out[7:0] received byte
);
	assign SCK = clk;
	// module Bit(
	// input clk,
	// input in,
	// input load,
	// output out
	// );

	// module PC(
	// input clk,
	// input [15:0] in,
	// input load,
	// input inc,
	// input reset,
	// output [15:0] out
	// );

	// 	module BitShift8L(
	// 	input clk,
	// 	input [7:0] in,
	// 	input inLSB,
	// 	input load,
	// 	input shift,
	// 	output reg [7:0] out
	// );

	reg sample, mosi;
	reg [2:0] sample_counter; // 3 bits for counting 0–7
	reg [15:0] inReg;
	// assign CSX = ~load; // active low?
	// assign SDO = inReg[15]; // MSB first?

	// save in for transmission in [t+1]
	always @(posedge clk) begin
		if (load)
			inReg <= in;
	end

	// hold sample signal for 8 cycles from load [t] to [t+8]
	always @(posedge clk) begin
		// init sampling when load is high [t+1]
		if (load) begin
			sample <= 1;
			sample_counter <= 3'd0;
		end
		else if (sample) begin
			// stop sampling after 8 bits [t+8]
			if (sample_counter == 3'd7) begin
				sample <= 0;
			end
			sample_counter <= sample_counter + 1; // it will roll over after 7
		end
	end

	// circular buffer to enable duplex comms with slave where:
	// slave MSB >= master LSB (MISO)
	// master MSB >= slave LSB (MOSI)
	// dual clock edge == read-before-write pattern?
	Bit miso (
		.clk(clk),
		.in(SDI), // MISO (MSB from slave)
		.load(sample), // sample on posedge for [t+8] after load
		.out(slaveMSB)
	);
	BitShift8L shiftreg (
		.clk(~clk), // invert clock to shift on negedge
		.in(8'd0), // init on load
		.inLSB(slaveMSB), // shift slaveMSB into masterLSB while sampling
		.load(load), // don't shift on load
		.shift(sample), // shift at negedge for [t+8] after load
		.out(out[7:0]) // master byte
	);
	always @(posedge clk) begin
		if (sample)
			mosi <= out[7]; // MSB first
	end
	assign SDO = mosi; // MOSI (masterMSB to slaveLSB)


endmodule
