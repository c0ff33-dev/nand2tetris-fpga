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
	input [15:0] inRAM, // RAM (0-3839)
	input [15:0] inIO0, // LED (4096)
	input [15:0] inIO1, // BUT (4097)
	input [15:0] inIO2, // UART_TX (4098)
	input [15:0] inIO3, // UART_RX (4099)
	input [15:0] inIO4, // SPI (4100)
	input [15:0] inIO5, // SRAM_A (4101)
	input [15:0] inIO6, // SRAM_D (4102)
	input [15:0] inIO7, // reserved [15:0]
	input [15:0] inIO8, // reserved [15:0]
	input [15:0] inIO9, // reserved [15:0]
	input [15:0] inIOA, // reserved [15:0]
	input [15:0] inIOB, // DEBUG0 (4107)
	input [15:0] inIOC, // DEBUG1 (4108)
	input [15:0] inIOD, // DEBUG2 (4109)
	input [15:0] inIOE, // DEBUG3 (4110)
	input [15:0] inIOF, // DEBUG4 (4111)
	output [15:0] out,
	output loadRAM, // RAM (0-3839)
	output loadIO0, // LED (4096)
	output loadIO1, // BUT (4097)
	output loadIO2, // UART_TX (4098)
	output loadIO3, // UART_RX (4099)
	output loadIO4, // SPI (4100)
	output loadIO5, // SRAM_A (4101)
	output loadIO6, // SRAM_D (4102)
	output loadIO7, // reserved [15:0]
	output loadIO8, // reserved [15:0]
	output loadIO9, // reserved [15:0]
	output loadIOA, // reserved [15:0]
	output loadIOB, // DEBUG0 (4107)
	output loadIOC, // DEBUG1 (4108)
	output loadIOD, // DEBUG2 (4109)
	output loadIOE, // DEBUG3 (4110)
	output loadIOF  // DEBUG4 (4111)
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
