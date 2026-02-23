`timescale 10ns/1ns
`default_nettype none
module HACK_tb();

    // IN,OUT
    reg CLK = 1;
    reg [1:0] BUT = 3;
    wire [1:0] LED;
    // wire UART_TX;
    // wire UART_RX;
    wire SPI_SDO;
    wire SPI_SDI;
    wire SPI_SCK;
    wire SPI_CSX;
    wire [17:0] SRAM_ADDR;
    wire [15:0] SRAM_DATA;
    wire SRAM_WEX;
    wire SRAM_OEX;
    wire SRAM_CSX;

    // Simulate SRAM 
    // page offset + current memory map max
    reg [15:0] sram[0:65536+24576];

    // init the array
    integer i;
    initial begin
        for (i = 0; i < 65536+24576; i = i + 1) begin
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

    // VGA test pattern: loaded after hardware VRAM init clears the range
    initial begin
        wait(HACK.vram_init_done);
        #10;

        // VGA pattern words at framebuffer base (row 0, cols 128..255) in run-mode SRAM page
        // bit=0 -> white pixel, bit=1 -> black pixel
        // data page + VRAM offset
        sram[65536+16384+8]  = 16'hAAAA; // 43690
        sram[65536+16384+9]  = 16'hBBBB; // 48059
        sram[65536+16384+10] = 16'hCCCC; // 52428
        sram[65536+16384+11] = 16'hDDDD; // 56797
        sram[65536+16384+12] = 16'hEEEE; // 61166
        sram[65536+16384+13] = 16'hFFFF; // 65535
        sram[65536+16384+14] = 16'h1111; // 4369
        sram[65536+16384+15] = 16'h2222; // 8738
    end

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

    wire VGA_HS;
    wire VGA_VS;
    wire [2:0] VGA_R;
    wire [2:0] VGA_G;
    wire [2:0] VGA_B;
    wire PS2_DATA;
    reg PS2_CLK_OUT;
    pullup(PS2_DATA); // open-drain emulation

    // Part
    HACK HACK(
        .CLK(CLK),             // external clock 100 MHz
        .BUT(BUT),             // user button  ("pushed down" == 0) ("up" == 1)
        .LED(LED),             // leds (0 off, 1 on)
        .SPI_SDO(SPI_SDO),     // SPI Serial Data Out
        .SPI_SDI(SPI_SDI),     // SPI Serial Data In
        .SPI_SCK(SPI_SCK),     // SPI Serial Clock
        .SPI_CSX(SPI_CSX),     // SPI Chip Select NOT
        .SRAM_ADDR(SRAM_ADDR), // SRAM address 18 Bit = 256K
        .SRAM_DATA(SRAM_DATA), // SRAM data 16 Bit
        .SRAM_WEX(SRAM_WEX),   // SRAM Write Enable NOT
        .SRAM_OEX(SRAM_OEX),   // SRAM Output Enable NOT
        .SRAM_CSX(SRAM_CSX),   // SRAM Chip Select NOT
        .PS2_CLK(PS2_CLK_OUT), // PS/2 clock (external)
        .PS2_DATA(PS2_DATA),   // PS/2 data
        .VGA_R(VGA_R),         // VGA RGB
        .VGA_G(VGA_G),         // VGA RGB
        .VGA_B(VGA_B),         // VGA RGB   
        .VGA_HS(VGA_HS),       // VGA horizontal sync   
        .VGA_VS(VGA_VS)        // VGA vertical sync
    );

    // Simulate
    always #0.5 CLK = ~CLK; // 100 MHz

    integer vga_samples = 0;
    integer vga_rgb_edges = 0;
    integer vga_tb_mismatches = 0;
    reg [15:0] e_vga_data = 16'h0000;
    reg [11:0] last_vga_rgb = 12'h000;
    always @(posedge HACK.vga_clk) begin
        if (!HACK.RST && HACK.vga.data_read &&
            (HACK.vga.o_addr >= 8) &&
            (HACK.vga.o_addr <= 15) &&
            vga_samples < 8) begin
            case (HACK.vga.o_addr)
                13'd8: e_vga_data =   16'hAAAA;
                13'd9: e_vga_data =   16'hBBBB;
                13'd10: e_vga_data =  16'hCCCC;
                13'd11: e_vga_data =  16'hDDDD;
                13'd12: e_vga_data =  16'hEEEE;
                13'd13: e_vga_data =  16'hFFFF;
                13'd14: e_vga_data =  16'h1111;
                13'd15: e_vga_data =  16'h2222;
                default: e_vga_data = 16'h0000;
            endcase
            if (sram[65536+16384+HACK.vga.o_addr] !== e_vga_data && sram[65536+16384+HACK.vga.o_addr] !== last_vga_rgb) begin
                $display("[ERROR] VGA testbench data mismatch addr=%0d expected=0x%04h got=0x%04h",
                         HACK.vga.o_addr, e_vga_data, sram[65536 + HACK.vga.o_addr]);
                vga_tb_mismatches = vga_tb_mismatches + 1;
            end
            vga_samples = vga_samples + 1;
        end

        if (!HACK.RST && ({VGA_R, VGA_G, VGA_B} != last_vga_rgb)) begin
            last_vga_rgb <= {VGA_R, VGA_G, VGA_B};
            vga_rgb_edges = vga_rgb_edges + 1;
        end
    end

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
                #250;              // hold low for 2.5 µs
                PS2_CLK_OUT = 1'b1;  // release clock high
                #250;              // clock high for 2.5 µs
            end

            // Release PS2_DATA after frame
            release PS2_DATA;
            PS2_CLK_OUT = 1'b1;  // idle state
        end
    endtask

    // ============================================================
    // SPI Flash Emulator (W25Q16BV)
    // ============================================================
    reg spi_sleep=1; // SDI is floating (z) when sleep enabled
    reg [31:0] spi_cmd=0;
    reg [95:0] spi=0; // 96 = size of largest value in tests
    assign SPI_SDI = (SPI_CSX | spi_sleep) ? 1'bz:spi[95];

    // simulate the SPI busy signal
    reg [2:0] busyCount=0;
    reg spi_reset=0;
    reg spi_init=1;
    wire spi_busy;
    assign spi_busy = ~spi_init;
    always @(posedge CLK) // override init state
        if (n<10) begin
            busyCount <= 0;
            spi_init <= 1;
        end
    always @(negedge (SPI_SCK)) begin
        if (spi_init==1) begin
            spi_init <= 0; // don't inc
            busyCount <= busyCount + 3'd1;
        end
        else if (busyCount==3'd7) begin
            spi_init <= 1;
            busyCount <= 0;
        end
        else
            busyCount <= busyCount + 3'd1;
    end

    always @(posedge (SPI_SCK)) begin
        if (spi_busy|busyCount==0) begin
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

    integer n=0;
    always @(posedge CLK) n=n+1;

    initial begin
        $dumpfile("HACK_tb.vcd");
        $dumpvars(0, HACK_tb);
        
        // Initialize PS2_DATA to high-Z (will be pulled high by external resistor)
        release PS2_DATA;
        
        $display("------------------------");
        $display("Test bench: Hack");
        $display("------------------------");

        // Initialize PS2_CLK to idle (high)
        PS2_CLK_OUT = 1'b1;
        
        // Wait for system reset + VRAM init to complete (~1.33ms)
        wait(!HACK.RST);
        #100;
        
        // Inject test characters: 'a', 'b', '1'
        transmit_ps2_frame(ascii_to_scancode(8'h61));  // 'a' = 0x1C
        #100;   // Short delay between characters for processing
        
        transmit_ps2_frame(ascii_to_scancode(8'h62));  // 'b' = 0x32
        #100;
        
        transmit_ps2_frame(ascii_to_scancode(8'h31));  // '1' = 0x16
        #100;
        
        #1250000;  // allow enough time for Math.jack
        $display("[RESULT] VGA sampled words=%0d rgb transitions=%0d tb_mismatches=%0d",
                 vga_samples, vga_rgb_edges, vga_tb_mismatches);
        if (vga_samples != 8) begin
            $display("[ERROR] VGA sample count mismatch expected=%0d got=%0d",
                     8, vga_samples);
        end
        if (vga_tb_mismatches != 0) begin
            $display("[ERROR] VGA testbench data did not match expected pattern");
        end
        $finish;
    end

endmodule
