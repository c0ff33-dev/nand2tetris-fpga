/**
 * The complete address space of the Hack computer's memory,
 * including RAM and memory-mapped I/O. 
 * The chip facilitates read and write operations, as follows:
 *     Read:  out(t) = Memory[address(t)](t)
 *     Write: if load(t-1) then Memory[address(t-1)](t) = in(t-1)
 * In words: the chip always outputs the value stored at the memory 
 * location specified by address. If load==1, the in value is loaded 
 * into the memory location specified by address. This value becomes 
 * available through the out output from the next time step onward.
 * Address space rules:
 * RAM 0x0000 - 0x0EFF (3840 words)
 * IO  0x1000 - 0x100F (maps to 16 different devices)
 * The behavior of IO addresses is described in 06_IO-Devices
 */

`default_nettype none
module Memory(
	input [15:0] address,
	input load,
	input [15:0] inRAM,
	input [15:0] inIO0,
	input [15:0] inIO1,
	input [15:0] inIO2,
	input [15:0] inIO3,
	input [15:0] inIO4,
	input [15:0] inIO5,
	input [15:0] inIO6,
	input [15:0] inIO7,
	input [15:0] inIO8,
	input [15:0] inIO9,
	input [15:0] inIOA,
	input [15:0] inIOB,
	input [15:0] inIOC,
	input [15:0] inIOD,
	input [15:0] inIOE,
	input [15:0] inIOF,
	output [15:0] out,
	output loadRAM,
	output loadIO0,
	output loadIO1,
	output loadIO2,
	output loadIO3,
	output loadIO4,
	output loadIO5,
	output loadIO6,
	output loadIO7,
	output loadIO8,
	output loadIO9,
	output loadIOA,
	output loadIOB,
	output loadIOC,
	output loadIOD,
	output loadIOE,
	output loadIOF
);

	// map adressses to wires for RAM3840 and the IO registers
	// mux input via address (memory mapped IO or RAM)
    assign out = (
		(address==4096) ? inIO0 :
		(address==4097) ? inIO1 :
		(address==4098) ? inIO2 :
		(address==4099) ? inIO3 :
  		(address==4100) ? inIO4 :
  		(address==4101) ? inIO5 :
 		(address==4102) ? inIO6 :
		(address==4103) ? inIO7 :
		(address==4104) ? inIO8 :
		(address==4105) ? inIO9 :
		(address==4106) ? inIOA :
		(address==4107) ? inIOB :
		(address==4108) ? inIOC :
		(address==4109) ? inIOD :
		(address==4110) ? inIOE :
		(address==4111) ? inIOF :
		inRAM);

	// mux load via address (memory mapped IO or RAM)
	assign loadRAM = (address<=3839) ? load : 0;
	assign loadIO0 = (address==4096) ? load : 0;
	assign loadIO1 = (address==4097) ? load : 0;
	assign loadIO2 = (address==4098) ? load : 0;
	assign loadIO3 = (address==4099) ? load : 0;
	assign loadIO4 = (address==4100) ? load : 0;
	assign loadIO5 = (address==4101) ? load : 0;
	assign loadIO6 = (address==4102) ? load : 0;
	assign loadIO7 = (address==4103) ? load : 0;
	assign loadIO8 = (address==4104) ? load : 0;
	assign loadIO9 = (address==4105) ? load : 0;
	assign loadIOA = (address==4106) ? load : 0;
	assign loadIOB = (address==4107) ? load : 0;
	assign loadIOC = (address==4108) ? load : 0;
	assign loadIOD = (address==4109) ? load : 0;
	assign loadIOE = (address==4110) ? load : 0;
	assign loadIOF = (address==4111) ? load : 0;

endmodule
