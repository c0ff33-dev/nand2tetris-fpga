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
        .SRAM_CSX(SRAM_CSX),   // SRAM Chip Select NOT
        
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

        #45000
        $finish;
    end

endmodule