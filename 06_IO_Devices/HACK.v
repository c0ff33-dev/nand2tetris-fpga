/**
 * The HACK computer, including CPU, ROM and RAM.
 * When RST is 0, the program stored in the computer's ROM executes.
 * When RST is 1, the execution of the program restarts. 
 * From this point onward the user is at the mercy of the software. 
 * In particular, depending on the program's code, the 
 * LED may show some output and the user may be able to interact 
 * with the computer via the BUT.
 */

`default_nettype none
module HACK(
    // inputs/outputs at this layer = wires to interfaces external to lattice
    // see .pcf files for mapping
    input  CLK,              // external clock 100 MHz    
    input  [1:0] BUT,        // user button (pushed "down"=0, "up"=1)
    output [1:0] LED,        // leds (0 off, 1 on)
    input  UART_RX,          // UART recieve
    output UART_TX,          // UART transmit
    output SPI_SDO,          // SPI Serial Data Out
    input  SPI_SDI,          // SPI Serial Data In
    output SPI_SCK,          // SPI Serial Clock
    output SPI_CSX,          // SPI Chip Select NOT
    output [17:0] SRAM_ADDR, // SRAM address 18 Bit = 256KB (64KB addressable)
    inout [15:0] SRAM_DATA,  // SRAM data 16 Bit
    output SRAM_WEX,         // SRAM Write Enable NOT
    output SRAM_OEX,         // SRAM Output Enable NOT
    output SRAM_CSX,         // SRAM Chip Select NOT
    output LCD_DCX,          // LCD Data/Command NOT
    output LCD_SDO,          // LCD Serial Data Out
    output LCD_SCK,          // LCD Serial Clock
    output LCD_CSX,          // LCD Chip Select NOT

    // AR1021 wires
    // input  RTP_SDI,       // RTP Serial Data In
    // output RTP_SDO,       // RTP Serial Data Out
    // output RTP_SCK        // RTP Serial Clock
    
    // NS2009 wires
    inout RTP_SDA,           // RTP Data line
    inout RTP_SCL            // RTP Serial Clock

);
    
    // Put your code here:
    wire clk,writeM,loadRAM,clkRST,RST,resLoad;
    wire sda_oe,scl_oe,sda_in,scl_in;
    wire loadIO0,loadIO1,loadIO2,loadIO3,loadIO4,loadIO5,loadIO6,loadIO7,loadIO8,loadIO9,loadIOA,loadIOB,loadIOC,loadIOD,loadIOE,loadIOF;
    wire [15:0] inIO1,inIO2,inIO3,inIO4,inIO5,inIO6,inIO7,inIO8,inIO9,inIOA,inIOB,inIOC,inIOD,inIOE,inIOF,outRAM;
    wire [15:0] addressM,pc,outM,inM,instruction,resIn,outLED,outROM,go_sram_addr,lcdBusy;

    // 25 MHz internal clock w/ 20μs initial reset period
    Clock25_Reset20 clock(
        .CLK(CLK), // external 100 MHz clock (pin)
        .clk(clk), // internal 25 MHz clock
        .reset(clkRST)
    );

    // reset PC during init & in [t+1] when GO load=1, both the load
    // and reset signal will shift high when the instruction is read
    // this mimics but is not the same as the iCE40 POR signal
    assign RST = clkRST | loadIO7;

    // CPU (ALU, A, D, PC)
    CPU cpu(
        .clk(clk),
        .inM(inM),
        .instruction(instruction),
        .reset(RST),
        .outM(outM), // combinational
        .writeM(writeM), // combinational
        .addressM(addressM), // clocked
        .pc(pc) // clocked
    );

    // Memory (map + combinational routing only)
    Memory mem(
        .address(addressM),
        .load(writeM),
        .inRAM(outRAM), // RAM (0-3583)
        .inIO0(outLED), // LED (4096)
        .inIO1(inIO1),  // BUT (4097)
        .inIO2(inIO2),  // UART_TX (4098)
        .inIO3(inIO3),  // UART_RX (4099)
        .inIO4(inIO4),  // SPI (4100)
        .inIO5(inIO5),  // SRAM_A (4101)
        .inIO6(inIO6),  // SRAM_D (4102)
        .inIO7(inIO7),  // GO (4103)
        .inIO8(inIO8),  // LCD8 (4104)
        .inIO9(inIO9),  // LCD16 (4105)
        .inIOA(inIOA),  // RTP (4106)
        .inIOB(inIOB),  // DEBUG0 (4107)
        .inIOC(inIOC),  // DEBUG1 (4108)
        .inIOD(inIOD),  // DEBUG2 (4109)
        .inIOE(inIOE),  // DEBUG3 (4110)
        .inIOF(inIOF),  // DEBUG4 (4111)
        .out(inM),
        .loadRAM(loadRAM), // RAM (0-3583)
        .loadIO0(loadIO0), // LED (4096)
        .loadIO1(loadIO1), // BUT (4097)
        .loadIO2(loadIO2), // UART_TX (4098)
        .loadIO3(loadIO3), // UART_RX (4099)
        .loadIO4(loadIO4), // SPI (4100)
        .loadIO5(loadIO5), // SRAM_A (4101)
        .loadIO6(loadIO6), // SRAM_D (4102)
        .loadIO7(loadIO7), // GO (4103)
        .loadIO8(loadIO8), // LCD8 (4104)
        .loadIO9(loadIO9), // LCD16 (4105)
        .loadIOA(loadIOA), // RTP (4106)
        .loadIOB(loadIOB), // DEBUG0 (4107)
        .loadIOC(loadIOC), // DEBUG1 (4108)
        .loadIOD(loadIOD), // DEBUG2 (4109)
        .loadIOE(loadIOE), // DEBUG3 (4110)
        .loadIOF(loadIOF)  // DEBUG4 (4111)
    );

    // ROM (BRAM buffer), 256 x 16 bit words (512 bytes)
    ROM rom(
        .clk(clk),
        .pc(pc),
        .instruction(outROM)
    );

    // BRAM (0-3583), 3584 x 16 bit words (7KB) 
    RAM3584 ram(
        .clk(clk),
        .address(addressM[11:0]),
        .in(outM),
        .load(loadRAM),
        .out(outRAM)
    );

    // LED 1/2 (4096), sharing 1 x 2 bit register
    Register led(
        .clk(clk),
        .in(outM),
        .load(loadIO0),
        .out(outLED) // 16 bit output going back to memory
    );
    assign LED = outLED[1:0]; // 2 bit output (pin)

    // BUT 1/2 (4097), sharing 1 x 2 bit register
    Register but(
        .clk(clk),
        .in({14'd0, BUT}),
        .load(1'b1),
        .out(inIO1) // memory map
    );

    // FUTURE: not enough logic cells to run UartTX/RX + RTP concurrently
    // // UART_TX (4098) @ 115200 baud (~14KB/sec)
    // UartTX uartTX(
    //     .clk(clk),
    //     .load(loadIO2),
    //     .in(outM), // transmit outM[7:0]
    //     .TX(UART_TX), // serial tx bit (pin)
    //     .out(inIO2) // memory map
    // );
    
    // // UART_RX (4099) @ 115200 baud (~14KB/sec)
    // UartRX uartRX(
    //     .clk(clk),
    //     .clear(loadIO3),
    //     .RX(UART_RX), // serial rx bit (pin)
    //     .out(inIO3) // memory map 
    // );

    // In the following component descriptions only 64KB or 
    // 32K x 16 bit words is addressable in current spec.
    
    // FUTURE: Document new spec in interpreter
        // original A instructions: 0x0-7FFF (32K words)
        // original C instructions: 0x8000-0xFFFF (32K words, 8K reserved)
        // new A instructions: 0x0-0xDFFF (56k words)
        // new C instructions: 0xE000-FFFF (8K words)

    // SPI (4100) controller for W25Q16BV (2MB flash @ 50/100 MHz read/write)
    SPI spi(
        .clk(clk),
        .in(outM), // [7:0] byte to send (address/command)
        .out(inIO4), // memory map
        .load(loadIO4), // SPI_* outputs wired to pins
        .SDI(SPI_SDI), // Serial Data In (MISO)
        .SCK(SPI_SCK), // Serial Clock
        .CSX(SPI_CSX), // Chip Select NOT (active low)
        .SDO(SPI_SDO) // Serial Data Out (MOSI)
    );

    // SRAM_A/SRAM_D (4101/4102): 16 bit address/data register for 
    // K6R4016V1D (512KB SRAM @ 100 MHz read/write)
    Register sram_addr (
        .clk(clk),
        .load(loadIO5),
        .in(outM),
        .out(inIO5)
    );
    SRAM_D sram_data (
        .clk(clk),
        .load(loadIO6), // 1=write enabled, else read enabled
        .in(outM), // input data (ignored on read)
        .out(inIO6), // output data (ignored on write)
        .mode(inIO7), // run_mode
        .DATA(SRAM_DATA), // data line (inout)
        .CSX(SRAM_CSX), // Chip Select NOT
        .OEX(SRAM_OEX), // Output Enable NOT
        .WEX(SRAM_WEX)  // Write Enable NOT
    );

    // GO (4103): emit instruction from BRAM/SRAM
    GO go(
        .clk(clk),
        .load(loadIO7),
        .pc(pc),
        .rom_data(outROM),
        .sram_addr_in(inIO5),
        .sram_data(inIO6),
        .sram_addr_out(go_sram_addr),
        .instruction(instruction),
        .out(inIO7)
    );
    // K6R4016V1D uses 18 bits but we address 16 LSB
    assign SRAM_ADDR = {2'd0, go_sram_addr};

    // LCD8/16 (4104/4105): ILI9341V 168KB VRAM (240x320 x 16bit colour depth)
    LCD lcd(
        .clk(clk), 
        .load(loadIO8),
        .load16(loadIO9),
        .in(outM),
        .out(lcdBusy), // LCD8/16 share one common circuit & busy signal
        .DCX(LCD_DCX), // Data/Command NOT
        .CSX(LCD_CSX), // Chip Select NOT
        .SDO(LCD_SDO), // Serial Data Out
        .SCK(LCD_SCK)  // Serial Clock
    );
    assign inIO8 = lcdBusy;
    assign inIO9 = lcdBusy;

    // RTP (4106): Resistive Touch Panel NS2009
    RTP rtp(
        .clk(clk),
        .load(loadIOA),
        .in(outM),
        .out(inIOA),
        .SDA(RTP_SDA),
        .SCL(RTP_SCL)
    );

    // RTP (4106): Resistive Touch Panel AR1021 (sim only)
    // RTP rtp(
    //     .clk(clk),
    //     .load(loadIOA),
    //     .in(outM),
    //     .out(inIOA),
    //     .SDI(RTP_SDI),   // RTP Serial Data In
    //     .SDO(RTP_SDO),   // RTP serial Data Out
    //     .SCK(RTP_SCK)    // RTP Serial Clock
    // );

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