/**
* RAM512 implements 512 Bytes of RAM addressed from 0 - 511
* out = M[address]
* if (load =i= 1) M[address][t+1] = in[t]
*/

`default_nettype none
module RAM512(
	input clk,
	input [8:0] address,
	input [15:0] in,
	input load,
	output [15:0] out
);
	
	// Mux using address[8] to select between two RAM256 blocks
	// Split address into high and low parts
	wire [7:0] addr_low = address[7:0];
    wire sel_high = address[8];
    wire [15:0] out_low, out_high;
    
    // Generate load signals for each RAM256 block
    wire load_low  = load & ~sel_high;
    wire load_high = load &  sel_high;

    // Instantiate the lower half RAM (0–255)
    RAM256 ram_low (
        .clk(clk),
        .address(addr_low),
        .in(in),
        .load(load_low),
        .out(out_low)
    );

    // Instantiate the upper half RAM (256–511)
    RAM256 ram_high (
        .clk(clk),
        .address(addr_low),
        .in(in),
        .load(load_high),
        .out(out_high)
    );

    // Demux the result so the result from the correct bank is emitted
    assign out = sel_high ? out_high : out_low;

endmodule
