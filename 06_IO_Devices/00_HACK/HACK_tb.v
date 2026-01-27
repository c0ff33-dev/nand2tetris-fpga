`timescale 10ns/1ns
`default_nettype none
module HACK_tb();

    // IN,OUT
    reg CLK = 1;
    reg [1:0] BUT = 3;
    wire [1:0] LED;
    wire UART_TX;
    wire UART_RX;
    wire SPI_SDO;
    wire SPI_SDI;
    wire SPI_SCK;
    wire SPI_CSX;
    wire [17:0] SRAM_ADDR;
    wire [15:0] SRAM_DATA;
    wire SRAM_WEX;
    wire SRAM_OEX;
    wire SRAM_CSX;
    wire LCD_DCX;
    wire LCD_SDO;
    wire LCD_SCK;
    wire LCD_CSX;

    // AR1021 wires
    // wire RTP_SDI;
    // wire RTP_SDO;
    // wire RTP_SCK;

    // NS2009 wires
    wire RTP_SDA;
    wire RTP_SCL;

    // Part
    HACK HACK(
        .CLK(CLK),             // external clock 100 MHz
        .BUT(BUT),             // user button  ("pushed down" == 0) ("up" == 1)
        .LED(LED),             // leds (0 off, 1 on)
        .UART_RX(UART_RX),     // UART receive
        .UART_TX(UART_TX),     // UART transmit
        .SPI_SDO(SPI_SDO),     // SPI Serial Data Out
        .SPI_SDI(SPI_SDI),     // SPI Serial Data In
        .SPI_SCK(SPI_SCK),     // SPI Serial Clock
        .SPI_CSX(SPI_CSX),     // SPI Chip Select NOT
        .SRAM_ADDR(SRAM_ADDR), // SRAM address 18 Bit = 256K
        .SRAM_DATA(SRAM_DATA), // SRAM data 16 Bit
        .SRAM_WEX(SRAM_WEX),   // SRAM Write Enable NOT
        .SRAM_OEX(SRAM_OEX),   // SRAM Output Enable NOT
        .SRAM_CSX(SRAM_CSX),   // SRAM Chip Select NOT
        .LCD_DCX(LCD_DCX),     // LCD Data/Command NOT
        .LCD_SDO(LCD_SDO),     // LCD Serial Data Out 
        .LCD_SCK(LCD_SCK),     // LCD Serial Clock
        .LCD_CSX(LCD_CSX),     // LCD Chip Select NOT

        // AR1021 wires
        // .RTP_SDI(RTP_SDI),  // RTP Serial Data In
        // .RTP_SDO(RTP_SDO),  // RTP Serial Data Out
        // .RTP_SCK(RTP_SCK)   // RTP Serial Clock

        // NS2009 wires
        .RTP_SDA(RTP_SDA),     // RTP Data line
        .RTP_SCL(RTP_SCL)      // RTP Serial Clock
    );

    // Simulate
    always #0.5 CLK = ~CLK; // 100 MHz
    integer n=0;
    always @(posedge CLK) n=n+1;

    // Compare
    reg [9:0] uart=10'b1111111111;
    reg [15:0] baudrate = 0;
    always @(posedge CLK)
        // not downclocked so need (216 * 4 = 864) for 25 MHz
        baudrate <= ((baudrate==864)?0:baudrate+1);
    always @(posedge CLK) begin
        // pack 82 (0x52) and 88 (0x58) into UART frames at 50/150µs respectively
        uart <= (n==5000)?((82<<2)+1):(n==15000)?((88<<2)+1):((baudrate==864)?{1'b1,uart[9:1]}:uart);
    end
    wire shift = (baudrate==864);
    assign UART_RX = uart[0];
    
    //Simulate SPI
    reg spi_sleep=1; // SDI is floating (z) when sleep enabled
    reg [31:0] spi_cmd=0;
    reg [95:0] spi=0; // 96 = size of largest value in tests
    assign SPI_SDI = (SPI_CSX | spi_sleep) ? 1'bz:spi[95];
    
    // simulate the SPI busy signal
    reg [2:0] busyCount=0;
    reg reset=0;
    reg init=1;
    wire busy;
    assign busy = ~init;
    always @(posedge CLK) // override init state
        if (n<10) begin
            busyCount <= 0; 
            init <= 1;
        end
    always @(negedge (SPI_SCK)) begin
        if (init==1) begin
            init <= 0; // don't inc
            busyCount <= busyCount + 3'd1;
        end
        else if (busyCount==3'd7) begin
            init <= 1;
            busyCount <= 0;
        end
        else
            busyCount <= busyCount + 3'd1;
    end
    
    always @(posedge (SPI_SCK)) begin
        if (busy|busyCount==0) begin
            spi <= {spi[95:0],1'b0}; // << 1 (BitShift8L(1))
            spi_cmd <= {spi_cmd[30:0],SPI_SDO}; // inject LSB (BitShift8L(2))
        end
    end

    // simulate the slave SPI buffer
    always @(posedge (SPI_CSX))
        spi_cmd <= 0;
    always @(spi_cmd) begin
        // should match after last SCK update is read in
        if (spi_cmd==32'h000000AB) spi_sleep <= 0; // wake
        if (spi_cmd==32'h000000B9) spi_sleep <= 1; // sleep
        if (spi_cmd==32'h03040000) spi <= {"SPI! 123", 32'd0}; // pad to the right so there aren't leading zeroes
        if (spi_cmd==32'h03010000) spi <= 96'h1001_FC10_1000_E308_0000_EA87; // leds.asm binary
    end

    //Simulate SRAM
    reg [16:0] sram[0:7];
    always @(posedge CLK)
        if (~SRAM_WEX&&SRAM_OEX&&~SRAM_CSX) sram[SRAM_ADDR] <= SRAM_DATA;
    assign SRAM_DATA = (~SRAM_CSX&&~SRAM_OEX)?sram[SRAM_ADDR]:16'bzzzzzzzzzzzzzzzz;
    //Simulate LCD
    reg [7:0] lcd_c;
    reg [15:0] lcd_d;
    always @(posedge LCD_SCK) begin
        lcd_c <= (~LCD_DCX)?{lcd_c[6:0],LCD_SDO}:lcd_c;
        lcd_d <= (LCD_DCX)?{lcd_d[6:0],LCD_SDO}:lcd_d;
    end
    always @(negedge LCD_CSX) begin
        lcd_c <= 0;
        lcd_d <= 0;
    end
    //simulate BUT
    always @(posedge CLK) begin
        if (n==10000) BUT<=0;
        if (n==20000) BUT<=1;
        if (n==30000) BUT<=2;
    end

    initial begin
        $dumpfile("HACK_tb.vcd");
        $dumpvars(0, HACK_tb);
        
        $display("------------------------");
        $display("Test bench: Hack");

        #45000
        $finish;
    end

endmodule
