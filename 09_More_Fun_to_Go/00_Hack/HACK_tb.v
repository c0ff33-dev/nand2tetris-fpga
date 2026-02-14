`timescale 10ns/1ns
`default_nettype none
module HACK_tb();

    // IN,OUT
    reg CLK = 1;
    reg [1:0] BUT = 3;
    wire [1:0] LED;
    wire UART_TX;
    wire UART_RX;
    wire [17:0] SRAM_ADDR;
    wire [15:0] SRAM_DATA;
    wire SRAM_WEX;
    wire SRAM_OEX;
    wire SRAM_CSX;

    // Simulate SRAM 
    // page offset + current memory map max
    reg [15:0] sram[0:65536+16383];

    // init the array
    integer i;
    initial begin
        for (i = 0; i < 65536+16383+1; i = i + 1) begin
            sram[i] = 16'd0;
        end
        // DEBUG
        // @GO // 0x1007
        // M=1 // 0xEFC8
        // <dead instruction during transition == pc>
        
        // @4112
        // D=M
        // @2 // line
        // 0;JMP
        sram[0] = 16'h1010; // 4112
        sram[1] = 16'hFC10; // 64528
        sram[2] = 16'h0002; // 2
        sram[3] = 16'hEA87; // 60039

        sram[65536+4112] = 16'd999;
        sram[65536+5000] = 16'd123;
    end

    // TODO: MS code
    always @(posedge CLK)
        if (~SRAM_WEX&&SRAM_OEX&&~SRAM_CSX) sram[SRAM_ADDR] <= SRAM_DATA;
    assign SRAM_DATA = (~SRAM_CSX&&~SRAM_OEX)?sram[SRAM_ADDR]:16'bz;
    
    wire [15:0] debug_sram, debug_sram0, debug_sram1, debug_sram2, debug_sram3;
    wire [15:0] debug_sram_p1_0, debug_sram_p1_1, debug_sram_p1_2;
    assign debug_sram0 = sram[0];
    assign debug_sram1 = sram[1];
    assign debug_sram2 = sram[2];
    assign debug_sram3 = sram[3];
    assign debug_sram_p1_0 = sram[65536+4112];
    assign debug_sram_p1_1 = sram[65536+4113];
    assign debug_sram_p1_2 = sram[65536+5000];

    // TODO: new wires
    // wire VGA_HS;
    // wire VGA_VS;
    // wire [3:0] VGA_R;
    // wire [3:0] VGA_G;
    // wire [3:0] VGA_B;
    // wire PS2_DATA;
    // wire PS2_CLK;

    // Part
    HACK HACK(
        .CLK(CLK),             // external clock 100 MHz
        .BUT(BUT),             // user button  ("pushed down" == 0) ("up" == 1)
        .LED(LED),             // leds (0 off, 1 on)
        .UART_RX(UART_RX),     // UART receive
        .UART_TX(UART_TX),     // UART transmit
        .SRAM_ADDR(SRAM_ADDR), // SRAM address 18 Bit = 256K
        .SRAM_DATA(SRAM_DATA), // SRAM data 16 Bit
        .SRAM_WEX(SRAM_WEX),   // SRAM Write Enable NOT
        .SRAM_OEX(SRAM_OEX),   // SRAM Output Enable NOT
        .SRAM_CSX(SRAM_CSX)    // SRAM Chip Select NOT
        
        // TODO: new ports
        // .VGA_HS(VGA_HS),
        // .VGA_VS(VGA_VS),
        // .VGA_R(VGA_R),
        // .VGA_G(VGA_G),
        // .VGA_B(VGA_B),
        // .PS2_DATA(PS2_DATA),
        // .PS2_CLK(PS2_CLK)
    );

    // Simulate
    always #0.5 CLK = ~CLK; // 100 MHz

    initial begin
        $dumpfile("HACK_tb.vcd");
        $dumpvars(0, HACK_tb);
        
        $display("------------------------");
        $display("Test bench: Hack");

        #20000
        $finish;
    end

endmodule