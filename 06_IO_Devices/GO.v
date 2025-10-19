/**
 * When load=1 `GO` switches HACK operation from boot mode to run mode.
 * In boot mode instruction is loaded from rom_data (BRAM).
 * In run mode instruction is loaded from sram_data (SRAM).
*/

`default_nettype none
module GO(
	input clk,
	input load,
	input [15:0] pc,
	input [15:0] rom_data,
	input [15:0] sram_addr,
	input [15:0] sram_data,
	output [15:0] SRAM_ADDR,
	output [15:0] instruction
);
	
	// 0 = boot mode (flash), 1 = run mode (sram)
	reg run_mode = 0;
	always @(posedge clk)
		if (load)
			run_mode <= 1;

	assign instruction = run_mode ? sram_data : rom_data;

	// in run mode CPU takes over driving SRAM_ADDR via pc
	// but in boot mode SRAM_ADDR is driven by the bootloader (boot.asm)
	assign SRAM_ADDR = run_mode ? pc : sram_addr;

endmodule
