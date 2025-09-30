/**
 * instruction memory at boot time 
 * The instruction memory is read only (ROM) and
 * preloaded with 256 x 16bit of Hack code holding the bootloader.
 * 
 * instruction = ROM[pc]
 */

`default_nettype none
module ROM(
	input [15:0] pc,
	output [15:0] instruction		
);

	// No need to implement this chip
	// ROM.hack is an ASCII encoded version of the binary
	// $readmemb is only used in simulation / will implicitly decode

	// ROM.bin is the raw binary uploaded with iceprogduino
	// `hexdump -C` will show the canonical representation of the binary
	// (after each line has been converted to int and split into 2 bytes)
	parameter ROMFILE = "ROM.hack";
	
	reg [15:0] mem [0:255];
	assign instruction = mem[pc[7:0]]; // read in one byte?
	
	initial begin
		$readmemb(ROMFILE,mem);
	end

endmodule
