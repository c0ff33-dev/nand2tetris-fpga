/**
 * UartTX controls transmission of bytes over UART.
 *
 * When load = 1 the chip starts serial transmission of the byte in[7:0] to the
 * TX line according to the protocoll 8N1 with 115200 baud. During transmission
 * out[15] is set to high (busy). The transmission is finished after 2170 clock 
 * cycles (10 byte at 217 cycles each). When transmission completes out[15] goes
 * low again (ready).
 */

`default_nettype none
module UartTX(
	input clk,
	input load, // 1 = initiate the transmission
	input [15:0] in, // [7:0] byte to send
	output TX, // transmission wire (serial)
	output [15:0] out // [15] 1 = busy, 0 = ready (memory mapped)
);

	reg r_busy;
	wire stop, load_stop, busy, is216, load_is216;
	wire [8:0] data;
	wire [15:0] txCount, baudCount;	

	// 0 = ready, 1 = busy
	Bit state(
		.clk(clk),
		.in(load), // set busy on new load
		.load(load_stop), // update when new load or done
		.out(busy)
	);
	assign out = {busy,15'b0}; // out[15] = busy

	// 115200 bits per second = 8.68μs
	// 217 cycles @ 25 MHz per bit
	// cycle through 0-216 to maintain the baud rate
	PC baud(
		.clk(clk),
		.inc(busy), // count while busy
		.load(1'b0),
		.in(16'b0),
		.reset(load_is216), // reset on load or 216 (max count)
		.out(baudCount) // current count
	);
	assign is216 = (baudCount == 216);
	assign load_is216 = (load | is216);

	// 8N1 protocol: 8 data bits, no parity bit, 1 stop bit
	// Start bit = 0
	// 8 data bits (LSB first)
	// Stop bit = 1, remains high until next transmission
	// bit counter rolls through 0-9 to track the 10 bits in the tx
	PC txIndex(
		.clk(clk),
		.inc(is216), // update index every 217 cycles
		.load(1'b0),
		.in(16'b0),
		.reset(load), // reset on new load
		.out(txCount) // track number of bits sent
	);

	// send the 10th bit + wait out the cycle before setting stop signal
	assign stop = (txCount==9 & is216);
	assign load_stop = (load | stop);

	// each shift cycles LSB out and MSB to the right
	// so starting with data[0] every 217th cycle sends a new bit
	BitShift9R shift(
		.clk(clk),
		.in({in[7:0],1'b0}), // fill LSB so first TX bit is zero (start bit)
		.inMSB(1'b1), // fill MSB with 1 post-shift (stop bit)
		.load(load), // load new data (don't shift)
		.shift(is216), // shift current data right
		.out(data)
	);

	// generic init handler, should work with ice40 + yosys
	reg init = 0;
	always @(posedge clk) begin
		if (!init) begin
			init <= 1;
		end
	end

	// if init set TX high
	// else send data[0] to pin when busy (transmit)
	// else keep line high at idle (still some noise at POR)
	assign TX = (~init ? 1'b1 : (busy ? data[0] : 1'b1));

endmodule
