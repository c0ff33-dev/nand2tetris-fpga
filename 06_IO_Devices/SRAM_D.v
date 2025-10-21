/**
 * SRAM_DATA controller for K6R4016V1D:
 * If load[t] == 1 then out[t+1] = in[t]
 *                      OEX[t+1] = 1
 *                      WEX[t+1] = 0
 *                      DATA[t+1] = in[t] (DATA is configured as output)
 * At any other time:
 *   out = DATA (DATA is configured as input)
 *   WEX=1, OEX=0
 * Always: CSX=0
 *
 * K6R4016V1D read/write latency is 5-10ns so at 25 MHz bus should be
 * stable for reading well before the end of [t+1].
 */
 
`default_nettype none
module SRAM_D(
	input clk,
	input load,
	input [15:0] in,   // SRAM_DATA (write)
	output [15:0] out, // SRAM_DATA (read)
	inout [15:0] DATA, // SRAM_DATA data line
	output CSX,        // SRAM_CSX chip_enable_not
	output OEX,        // SRAM_OEX output_enable_not
	output WEX         // SRAM_WEX write_enable_not
);
	wire dffLoad;
	wire [15:0] _DATA, data, _out;

	// repeat load in [t+1] for InOut
	DFF dff_load (
        .clk(clk),
        .in(load),
        .out(dffLoad)
    );

	// register outgoing data to clk domain
	Register reg_data (
        .clk(clk),
        .in(in),
        .load(load),
        .out(data)
    );

	// register control wires to clk domain
	reg csx=0; // chip select not (remains low)
	reg oex=0; // output enable not
	reg wex=1; // write enable not
	always @(posedge clk) begin
		if (load) begin
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
		end
	end

	// bidirectional data bus (combinational)
	InOut io (
		.PIN(_DATA), // inout=dataW when dir=1, else 16'bz
		.dataW(data), // outgoing data
		.dataR(_out), // incoming data
		.dir(dffLoad) // 1=write to SRAM in [t+1] from load
	);

	assign OEX = oex;
	assign WEX = wex;
	assign CSX = csx;
	assign DATA = init ? _DATA : 16'bzzzzzzzzzzzzzzzz;
	assign out = init ? _out : 16'bzzzzzzzzzzzzzzzz;

endmodule
