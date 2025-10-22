/**
 * SRAM_DATA controller for K6R4016V1D:
 * If load[t] == 1 then out[t+1] = in[t]
 *                      OEX[t+1] = 1
 *                      WEX[t+1] = 0
 *                      DATA[t+1] = in[t] (DATA is configured as output)
 * At any other time:
 *   out = DATA (DATA is configured as input)
 *   WEX=1, OEX=0
 *   CSX=1 (disabled) during init then 0 (enabled) afterwards
 *
 * K6R4016V1D read/write latency is 5-10ns so at 25 MHz bus should be
 * stable well before it is sampled (same cycle as emitted or [t+1] 
 * from initial load=1 signal).
 */
 
`default_nettype none
module SRAM_D(
	input clk,
	input load,
	input [15:0] in,   // SRAM_DATA (write)
	output reg [15:0] out, // SRAM_DATA (read)
	inout [15:0] DATA, // SRAM_DATA data line
	output CSX,        // SRAM_CSX chip_enable_not
	output OEX,        // SRAM_OEX output_enable_not
	output WEX         // SRAM_WEX write_enable_not
);
	wire _load, dffLoad;
	wire [15:0] _dataOut, data, dataOut;

	// register outgoing data to clk domain
	// latch the write data on first cycle load is high
	Register reg_data (
        .clk(clk),
        .in(in),
        .load(_load),
        .out(data)
    );

	// emit the latched write data on 2nd cycle
	// repeat load in [t+1] for InOut
	DFF dff_load (
        .clk(clk),
        .in(load),
        .out(dffLoad)
    );

	// register control wires to clk domain
	reg csx=1; // chip select not (remains low after init)
	reg oex=0; // output enable not
	reg wex=1; // write enable not
	always @(posedge clk) begin
		if (_load) begin
			// enable write
			oex <= 1'b1;
			wex <= 1'b0;
		end
		else begin
			// enable read
			oex <= 1'b0;
			wex <= 1'b1;
		end
	end

	reg init = 0;
	always @(posedge clk) begin
		if (~init) begin
			init <= 1;
			csx <= 0;
		end
	end

	// bidirectional data bus (combinational)
	// disconnected (high impedence) when dir=0
	InOut io (
		.PIN(DATA), // inout=dataW when dir=1, else 16'bz
		.dataW(data), // outgoing data
		.dataR(dataOut), // incoming data
		.dir(dffLoad) // 1=write data to SRAM, else read
	);
	assign OEX = oex;
	assign WEX = wex;
	assign CSX = csx;

	// original design: wire straight to out without latching (combinational read)
	// assign out = init ? out : 16'bzzzzzzzzzzzzzzzz;

	assign _load = init ? load : 1'b0;

	// new design: latch output to negedge (syncronous read, same as BRAM)
	// but never the inout port itself
	always @(negedge clk) begin
		if (dffLoad)
			out <= init ? dataOut : 16'bzzzzzzzzzzzzzzzz;
		else
			out <= init ? out : 16'bzzzzzzzzzzzzzzzz;
	end
	
endmodule
