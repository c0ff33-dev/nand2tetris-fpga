/**
 * Instruction memory at boot time.
 * The instruction memory is read only (ROM) and
 * preloaded with 256 x 16 bits of Hack code holding the bootloader.
 * 
 * instruction = ROM[pc]
 */

`default_nettype none
module ROM(
    input clk,
    input [15:0] pc,
    output reg [15:0] instruction
);

    // No need to implement this chip
    // ROM.hack is an ASCII encoded version of the binary
    // $readmemb will decode ASCII encoded binary

    // ROM.bin is the raw binary when uploading with iceprogduino
    // `hexdump -C` will show the canonical representation of the binary
    // (after each line has been converted to int and split into 2 bytes)
    parameter ROMFILE = "ROM.hack";
    reg [15:0] mem [0:255];
    
    // new: synchronous read
    always @(negedge clk) begin
        instruction <= mem[pc[7:0]];
    end

    // original: asyncronous read
    // assign instruction = mem[pc[7:0]];
    
    // init BRAM with values read in from ROMFILE at build time
    initial begin
        $readmemb(ROMFILE,mem);
    end

endmodule
