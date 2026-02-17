`timescale 10ns/1ns
`default_nettype none
module HACK_tb();

    // IN,OUT
    reg CLK = 1;
    reg [1:0] BUT = 3;
    wire [1:0] LED;
    // wire UART_TX;
    // wire UART_RX;
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
    wire PS2_DATA;
    reg PS2_CLK_OUT;  // separate PS/2 clock (5 MHz)
    
    // Pull-up for PS2_DATA (open-drain simulation)
    pullup(PS2_DATA);

    // Part
    HACK HACK(
        .CLK(CLK),             // external clock 100 MHz
        .BUT(BUT),             // user button  ("pushed down" == 0) ("up" == 1)
        .LED(LED),             // leds (0 off, 1 on)
        // .UART_RX(UART_RX),     // UART receive
        // .UART_TX(UART_TX),     // UART transmit
        .SRAM_ADDR(SRAM_ADDR), // SRAM address 18 Bit = 256K
        .SRAM_DATA(SRAM_DATA), // SRAM data 16 Bit
        .SRAM_WEX(SRAM_WEX),   // SRAM Write Enable NOT
        .SRAM_OEX(SRAM_OEX),   // SRAM Output Enable NOT
        .SRAM_CSX(SRAM_CSX),    // SRAM Chip Select NOT
        
        // TODO: new ports
        // .VGA_HS(VGA_HS),
        // .VGA_VS(VGA_VS),
        // .VGA_R(VGA_R),
        // .VGA_G(VGA_G),
        // .VGA_B(VGA_B),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK_OUT)
    );

    // Simulate
    always #0.5 CLK = ~CLK; // 100 MHz

    // ============================================================
    // PS/2 Keyboard Emulator: ASCII-to-Scancode Mapping
    // ============================================================
    function [7:0] ascii_to_scancode(input [7:0] ascii_char);
        case (ascii_char)
            8'h61:   ascii_to_scancode = 8'h1C;  // 'a'
            8'h62:   ascii_to_scancode = 8'h32;  // 'b'
            8'h31:   ascii_to_scancode = 8'h16;  // '1'
            default: ascii_to_scancode = 8'h00;  // unsupported char
        endcase
    endfunction

    // Compute odd parity for 8-bit value
    function parity_8(input [7:0] data);
        parity_8 = ~(^data);  // odd parity: flip XOR result
    endfunction

    // ============================================================
    // PS/2 Frame Transmitter Task - Fast Event-Driven Simulation
    // Transmits a single 11-bit PS/2 frame: START + 8 DATA (LSB first) + PARITY + STOP
    // Uses direct bit-time delays with slow clock (~200 kHz) vs FPGA 6.25 MHz (31x ratio)
    // ============================================================
    task transmit_ps2_frame(input [7:0] scancode);
        reg [10:0] frame;  // 11-bit frame: bit 0=START, bits 1-8=DATA, bit 9=PARITY, bit 10=STOP
        integer i;
        begin
            // Assemble frame: START=0, DATA[7:0], PARITY, STOP=1
            frame[0] = 1'b0;                           // START bit
            frame[8:1] = scancode;                     // DATA bits (LSB first)
            frame[9] = parity_8(scancode);             // PARITY bit
            frame[10] = 1'b1;                          // STOP bit

            $display("[PS/2] Transmitting scancode 0x%02H, frame=0b%011b", scancode, frame);

            // Simulate PS/2 clock and data line transitions
            // Each bit transmission: drive data, clock pulse, release data
            // Using 500 time units per bit (~200 kHz at 10ns timescale, 31x slower than 6.25 MHz FPGA clock)
            for (i = 0; i < 11; i = i + 1) begin
                // Drive PS2_DATA to frame bit value (0=drive low, 1=release to high-Z)
                if (frame[i] == 1'b0) begin
                    force PS2_DATA = 1'b0;  // actively driving
                end else begin
                    release PS2_DATA;  // release to high-Z (external pull-up will pull high)
                end
                
                // Simulate PS/2 clock pulse (pull low then release)
                PS2_CLK_OUT = 1'b0;  // clock pulls low during bit
                #250;                // hold low for 2.5 µs
                PS2_CLK_OUT = 1'b1;  // release clock high
                #250;                // clock high for 2.5 µs
            end

            // Release PS2_DATA after frame
            release PS2_DATA;
            PS2_CLK_OUT = 1'b1;  // idle state
            $display("[PS/2] Frame transmission complete\n");
        end
    endtask

    initial begin
        $dumpfile("HACK_tb.vcd");
        $dumpvars(0, HACK_tb);
        
        // Initialize PS2_DATA to high-Z (will be pulled high by external resistor)
        release PS2_DATA;
        
        $display("------------------------");
        $display("Test bench: Hack");        
        $display("PS/2 Keyboard Emulator - Injecting test characters");
        $display("------------------------");

        // Initialize PS2_CLK to idle (high)
        PS2_CLK_OUT = 1'b1;
        
        // Wait for system reset and stabilization (20 µs at 10ns timescale = 2000 units)
        #2100;
        
        // Inject test characters: 'a', 'b', '1'
        $display("\n[STIM] Injecting character 'a'...");
        transmit_ps2_frame(ascii_to_scancode(8'h61));  // 'a' = 0x1C
        #100;   // Short delay between characters for processing
        
        $display("\n[STIM] Injecting character 'b'...");
        transmit_ps2_frame(ascii_to_scancode(8'h62));  // 'b' = 0x32
        #100;
        
        $display("\n[STIM] Injecting character '1'...");
        transmit_ps2_frame(ascii_to_scancode(8'h31));  // '1' = 0x16
        #100;
        
        $display("\n[STIM] Character injection complete. Waiting for processing...");
        #2000;  // Short final settling time
        $finish;
    end

endmodule