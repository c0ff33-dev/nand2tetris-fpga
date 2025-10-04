/**
 * UartRX receives bytes over UART
 *
 * When clear = 1 the chip clears the receive buffer and is ready to receive
 * next byte. out[15] is set to 1 to show, that chip is ready to receive next
 * byte. When RX goes low the chip starts sampling the RX line. After reading
 * of byte completes, chip ouputs the received byte to out[7:0]] with out[15]=0.
 */

`default_nettype none
module UartRX(
	input clk,
	input clear,
	input RX, // transmission wire (serial)
	output [15:0] out
);

	wire start, busy, rx, stop, start_clear, is108, is216;
	wire [15:0] baudCount, rxCount, clear_data;
	wire [8:0] data;

	// set start when rx drops low (start bit) & ready to rx
	// reset when rx finished (stop) or cleared
	// note: stop is only high for 1 cycle
	assign start = stop ? 1'b0 : (~rx & ~busy);
	assign start_clear = (start | stop | clear);

	// 0 = ready, 1 = busy
	Bit state(
		.clk(clk),
		.in(start),
		.load(start_clear), // update on new read or clear
		.out(busy)
	);

	// 115200 bits per second = 8.68us
	// 217 cycles @ 25 MHz per bit
	// cycle through 0-216 to maintain the baud rate
	PC baud(
		.clk(clk),
		.inc(busy), // count while busy
		.load(1'b0),
		.in(16'b0),
		.reset(is216), // reset on 216 (max count)
		.out(baudCount) // current count
	);
	assign is108 = (baudCount == 108);
	assign is216 = (baudCount == 216);

	// 8N1 protocol: 8 data bits, no parity bit, 1 stop bit
	// Start bit = 0
	// 8 data bits (LSB first)
	// Stop bit = 1, remains high until next transmission
	// bit counter rolls through 0-9 to track the 10 bits in the rx
	PC txIndex(
		.clk(clk),
		.inc(is216), // update index every 217 cycles
		.load(1'b0),
		.in(16'b0),
		.reset(start), // reset on new read
		.out(rxCount) // track number of bits read
	); 

	// store RX bit (sync RX to clk domain)
	DFF dff(
		.clk(clk),
		.in(RX), // read data from pin
		.out(rx)
	);

	// FIXME: rx/shift looks right but still arrives 2 cycles late
	
	// each shift cycles LSB out and MSB to the right
	//  tx/rx: 0xxxxxxxx1 (pre-shift)
	//  shift: --------- // init
	// shift0: 0-------- >> -0-------
	// shift1: x0------- >> -x0------
	// shift2: xx0------ >> -xx0-----
	// shift3: xxx0----- >> -xxx0----
	// shift4: xxxx0---- >> -xxxx0---
	// shift5: xxxxx0--- >> -xxxxx0--
	// shift6: xxxxx0--- >> -xxxxx0-- 
	// shift7: xxxxxx0-- >> -xxxxxx0-
	// shift8: xxxxxxx0- >> -xxxxxxx0 
	// shift9: xxxxxxxx0 >> -xxxxxxxx
	BitShift9R shift(
		.clk(clk),
		.in(9'b111111111), // init
		.inMSB(rx), // load rx bit into MSB when sampled
		.load(start), // init
		.shift(is108), // sample at midpoint & shift right
		.out(data)
	);

	// clear: reset register and set [15]=1 (waiting)
	// else: pad data and set [15]=0 (done)
	assign clear_data = clear ? 16'h8000 : {8'd0,data[7:0]};

	// allow load when clearing or completed
	assign stop = (clear | (rxCount==9 & is216));

	// buffer the output so only complete results are emitted
	Register buffer(
		.clk(clk),
		.in(clear_data),
		.load(stop),
		.out(out)
	);

endmodule
