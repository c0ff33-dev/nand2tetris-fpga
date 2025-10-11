/**
* RAM3840 implements 3840 Bytes of RAM addressed from 0 - 3839
* out = M[address]
* if (load =i= 1) M[address][t+1] = in[t]
*/

`default_nettype none
module RAM3840(
	input clk,
	input [11:0] address,
	input [15:0] in,
	input load,
	output [15:0] out
);
	
	// Address decoding mux
    wire [2:0] bank_select = address[11:9];
    wire [8:0] local_address = address[8:0];

    // Load enable signals per bank
    wire load0 = load & (bank_select == 3'd0);
    wire load1 = load & (bank_select == 3'd1);
    wire load2 = load & (bank_select == 3'd2);
    wire load3 = load & (bank_select == 3'd3);
    wire load4 = load & (bank_select == 3'd4);
    wire load5 = load & (bank_select == 3'd5);
    wire load6 = load & (bank_select == 3'd6);
    wire load7 = load & (bank_select == 3'd7);

    // Outputs from each bank
    wire [15:0] out0, out1, out2, out3, out4, out5, out6, out7;

    // Instantiate 8 RAM512 blocks
    RAM512 ram0 (.clk(clk), .address(local_address), .in(in), .load(load0), .out(out0));
    RAM512 ram1 (.clk(clk), .address(local_address), .in(in), .load(load1), .out(out1));
    RAM512 ram2 (.clk(clk), .address(local_address), .in(in), .load(load2), .out(out2));
    RAM512 ram3 (.clk(clk), .address(local_address), .in(in), .load(load3), .out(out3));
    RAM512 ram4 (.clk(clk), .address(local_address), .in(in), .load(load4), .out(out4));
    RAM512 ram5 (.clk(clk), .address(local_address), .in(in), .load(load5), .out(out5));
    RAM512 ram6 (.clk(clk), .address(local_address), .in(in), .load(load6), .out(out6));
    // FIXME: ran out of BELs for additional BRAM
    // RAM512 ram7 (.clk(clk), .address(local_address), .in(in), .load(load7), .out(out7));

    // Demux based on selected bank
    assign out = (bank_select == 3'd0) ? out0 :
                 (bank_select == 3'd1) ? out1 :
                 (bank_select == 3'd2) ? out2 :
                 (bank_select == 3'd3) ? out3 :
                 (bank_select == 3'd4) ? out4 :
                 (bank_select == 3'd5) ? out5 :
                 (bank_select == 3'd6) ? out6 :
                 (bank_select == 3'd7) ? out7 :
                 16'bx; // should never happen

endmodule
