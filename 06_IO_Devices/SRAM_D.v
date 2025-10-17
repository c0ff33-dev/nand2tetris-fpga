/**
 * SRAM_DATA controller:
 * If load[t] == 1 then out[t+1] = in[t]
 *                      OEX[t+1] = 1
 *                      WEX[t+1] = 0
 *                      DATA[t+1] = in[t] (DATA is configured as output)
 * At any other time:
 * out = DATA (DATA is configured as input)
 * CSX =0;
 */
`default_nettype none
module SRAM_D(
	input clk,
	input load,
	input [15:0] in, // SRAM_ADDR (least significant 16 bits of 18)
	output [15:0] out, // SRAM_DATA
	inout [15:0] DATA,	// SRAM_DATA data line
	output CSX, 		// SRAM_CSX chip_enable_not
	output OEX,		// SRAM_OEX output_enable_not
	output WEX			// SRAM_WEX write_enable_not
);
	wire _load, dffLoad;
	wire [15:0] _out, addrA, data;

	// delay load by one cycle
	DFF dff_load (
        .clk(clk),
        .in(_load),
        .out(dffLoad)
    );

	// data to be stored
	Register reg_data (
        .clk(clk),
        .in(in),
        .load(_load),
        .out(data)
    );

	// bidirectional data bus
	InOut io (
		.PIN(DATA), // inout=dataW when dir=1, else 16'bz
		.dataW(data), // outgoing data
		.dataR(_out), // incoming data
		.dir(dffLoad) // 1=write data to SRAM, else read
	);

	// control wires
	reg csx=0; // chip select not (remains low)
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
		end
	end

	assign OEX = oex;
	assign WEX = wex;
	assign CSX = csx;
	assign _load = init ? load : 1'b0;
	assign out = init ? _out : 16'bzzzzzzzzzzzzzzzz;
	
endmodule
