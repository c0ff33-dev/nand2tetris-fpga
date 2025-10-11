/**
 * The HACK computer, including CPU, ROM and RAM.
 * When RST is 1, the program stored in the computer's ROM executes.
 * When RST is 0, the execution of the program restarts. 
 * Thus, to start a program's execution, reset must be pushed "down" (0)
 * and "up" (1). From this point onward the user is at the mercy of 
 * the software. In particular, depending on the program's code, the 
 * LED may show some output and the user may be able to interact 
 * with the computer via the BUT.
 */

 // TODO: sync 5/6/7 HACK files

`default_nettype none
module HACK( 
    input  CLK,				// external clock 100 MHz	
	input  [1:0] BUT,		// user button  ("pushed down" == 0) ("up" == 1)
	input  CDONE,			// configuration done (ice40 only)
	output [1:0] LED,		// leds (0 off, 1 on)
	input  UART_RX,			// UART recieve
	output UART_TX,			// UART transmit
	output SPI_SDO,			// SPI data out
	input  SPI_SDI,			// SPI data in
	output SPI_SCK,			// SPI serial clock
	output SPI_CSX,			// SPI chip select not
	output [17:0] SRAM_ADDR,// SRAM address 18 Bit = 256K
	inout [15:0] SRAM_DATA,	// SRAM data 16 Bit
	output SRAM_WEX,		// SRAM write_enable_not
	output SRAM_OEX,		// SRAM output_enable_not
	output SRAM_CSX, 		// SRAM chip_select_not
	output LCD_DCX,			// LCD data/command not
	output LCD_SDO,			// LCD data out 
	output LCD_SCK,			// LCD serial clock
	output LCD_CSX,			// LCD chip select not
	input  RTP_SDI,			// RTP data in s
	output RTP_SDO,			// RTP data out 
	output RTP_SCK			// RTP serial clock
);

	wire clk,writeM,loadRAM,RST,resLoad;
	wire loadIO0,loadIO1,loadIO2,loadIO3,loadIO4,loadIOB,loadIOC,loadIOD,loadIOE,loadIOF;
	wire [15:0] inIO1,inIO2,inIO3,inIO4,inIOB,inIOC,inIOD,inIOE,inIOF,outRAM;
	wire [15:0] addressM,pc,outM,inM,instruction,resIn,outLED;

	// 25 MHz internal clock w/ 20μs initial reset period
	Clock25_Reset20 clock(
		.CLK(CLK), // external 100 MHz clock (pin)
		.clk(clk), // internal 25 MHz clock
		.reset(RST)
	);

	// CPU (ALU, A, D, PC)
	CPU cpu(
		.clk(clk),
		.inM(inM),
		.instruction(instruction),
		.reset(RST),
		.outM(outM),
		.writeM(writeM),
		.addressM(addressM),
		.pc(pc)
	);

	// Memory (map only)
	Memory mem(
		.address(addressM),
		.load(writeM),
		.inRAM(outRAM), // RAM (0-3839)
		.inIO0(outLED), // LED (4096)
		.inIO1(inIO1),  // BUT (4097)
		.inIO2(inIO2),  // UART_TX (4098)
		.inIO3(inIO3),  // UART_RX (4099)
		.inIO4(inIO4),  // SPI (4100)
		.inIO5(resIn),  // reserved (undefined)
		.inIO6(resIn),  // reserved (undefined)
		.inIO7(resIn),  // reserved (undefined)
		.inIO8(resIn),  // reserved (undefined)
		.inIO9(resIn),  // reserved (undefined)
		.inIOA(resIn),  // reserved (undefined)
		.inIOB(inIOB),  // DEBUG0 (4107)
		.inIOC(inIOC),  // DEBUG1 (4108)
		.inIOD(inIOD),  // DEBUG2 (4109)
		.inIOE(inIOE),  // DEBUG3 (4110)
		.inIOF(inIOF),  // DEBUG4 (4111)
		.out(inM),
		.loadRAM(loadRAM), // RAM (0-3839)
		.loadIO0(loadIO0), // LED (4096)
		.loadIO1(loadIO1), // BUT (4097)
		.loadIO2(loadIO2), // UART_TX (4098)
		.loadIO3(loadIO3), // UART_RX (4099)
		.loadIO4(loadIO4), // SPI (4100)
		.loadIO5(resLoad), // reserved (undefined)
		.loadIO6(resLoad), // reserved (undefined)
		.loadIO7(resLoad), // reserved (undefined)
		.loadIO8(resLoad), // reserved (undefined)
		.loadIO9(resLoad), // reserved (undefined)
		.loadIOA(resLoad), // reserved (undefined)
		.loadIOB(loadIOB), // DEBUG0 (4107)
		.loadIOC(loadIOC), // DEBUG1 (4108)
		.loadIOD(loadIOD), // DEBUG2 (4109)
		.loadIOE(loadIOE), // DEBUG3 (4110)
		.loadIOF(loadIOF)  // DEBUG4 (4111)
	);

	// ROM (BRAM buffer), 256 x 16 bit words
	ROM rom(
		.clk(clk),
		.pc(pc),
		.instruction(instruction)
	);

	// BRAM (0-3839 x 16 bit words)
	RAM3840 ram(
		.clk(clk),
		.address(addressM[11:0]),
		.in(outM),
		.load(loadRAM),
		.out(outRAM)
	);

	// LED (4096)
	Register led(
		.clk(clk),
		.in(outM),
		.load(loadIO0),
		.out(outLED) // 16 bit output going back to memory
	);
	assign LED = outLED[1:0]; // 2 bit output (pin)

	// BUT (4097)
	Register but(
		.clk(clk),
		.in({14'd0, BUT}), // concat 14 bits for padding
		.load(1'b1),
		.out(inIO1) // memory map
	);

	// UART_TX (4098)
	// R: busy signal, [15]=1 busy, [15]=0 ready
	// W: send byte
	UartTX uartTX(
		.clk(clk),
		.CDONE(CDONE), // configuration done (ice40 only)
		.load(loadIO2),
		.in(outM), // transmit outM[7:0]
		.TX(UART_TX), // serial tx bit (pin)
		.out(inIO2) // memory map
	);

	// UART_RX (4099)
	// R: out[15]=1 no data (0x8000), else out[7:0]=byte
	// W: 1 = clear data register
	UartRX uartRX(
		.clk(clk),
		.CDONE(CDONE), // configuration done (ice40 only)
		.clear(loadIO3),
		.RX(UART_RX), // serial rx bit (pin)
		.out(inIO3) // memory map 
	);

	// SPI interface for W25Q16BV w/ 2MB flash (4100)
	// R: out[15]=1 if busy, out[7:0] received byte
	// W: command byte outM[7:0] +
	// W: outM[8]=1 pull CSX high (no send), outM[8]=0 send (CSX=0)
	SPI spi(
		.clk(clk),
		.CDONE(CDONE), // configuration done (ice40 only)
		.in(outM), // [7:0] byte to send (address/command)
		.out(inIO4), // memory map
		.load(loadIO4), // SPI_* outputs wired to pins
		.SDI(SPI_SDI), // serial data in (MISO)
		.SCK(SPI_SCK), // serial clock
		.CSX(SPI_CSX), // chip select not (active low)
		.SDO(SPI_SDO) // serial data out (MOSI)
	);

	// additional registers
	// DEBUG0 (4107)
	Register debug0(
		.clk(clk),
		.in(outM),
		.load(loadIOB),
		.out(inIOB)
	);

	// DEBUG1 (4108)
	Register debug1(
		.clk(clk),
		.in(outM),
		.load(loadIOC),
		.out(inIOC)
	);

	// DEBUG2 (4109)
	Register debug2(
		.clk(clk),
		.in(outM),
		.load(loadIOD),
		.out(inIOD)
	);

	// DEBUG3 (4110)
	Register debug3(
		.clk(clk),
		.in(outM),
		.load(loadIOE),
		.out(inIOE)
	);

	// DEBUG4 (4111)
	Register debug4(
		.clk(clk),
		.in(outM),
		.load(loadIOF),
		.out(inIOF)
	);

endmodule
