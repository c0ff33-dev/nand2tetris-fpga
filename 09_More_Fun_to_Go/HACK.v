/**
 * The HACK computer, including CPU, ROM and RAM.
 * When RST is 0, the program stored in the computer's ROM executes.
 * When RST is 1, the execution of the program restarts. 
 * From this point onward the user is at the mercy of the software. 
 * In particular, depending on the program's code, the 
 * LED may show some output and the user may be able to interact 
 * with the computer via the BUT.
 */

// FUTURE: if == logical operators, combinational == bitwise operators

`default_nettype none
module HACK(
    // inputs/outputs at this layer = wires to interfaces external to lattice
    // see .pcf files for mapping
    input  CLK,              // external clock 100 MHz    
    input  [1:0] BUT,        // user button (pushed "down"=0, "up"=1)
    output [1:0] LED,        // leds (0 off, 1 on)
    input  UART_RX,          // UART recieve
    output UART_TX,          // UART transmit
    output [17:0] SRAM_ADDR, // SRAM address 18 Bit = 256KB (64KB addressable)
    inout  [15:0] SRAM_DATA, // SRAM data 16 Bit
    output SRAM_WEX,         // SRAM Write Enable NOT
    output SRAM_OEX,         // SRAM Output Enable NOT
    output SRAM_CSX          // SRAM Chip Select NOT
);
    
    wire clk,clkVGA,writeM,loadRAM,clkRST,RST;
    wire loadIO0,loadIO1,loadIO2,loadIO3,loadIO4,loadIO5,loadIO6,loadIO7,loadIO8,loadIO9,loadIOA,loadIOB,loadIOC,loadIOD,loadIOE,loadIOF;
    wire [2:0] phase;
    wire [15:0] inIO1,inIO2,inIO3,inIO4,inIO5,inIO6,inIO7,inIO8,inIO9,inIOA,inIOB,inIOC,inIOD,inIOE,inIOF,outRAM;
    wire [15:0] addressM,pc,outM,inM,instruction,outLED,outROM,go_sram_addr;

    // 25 MHz internal clock w/ 20μs initial reset period
    Clock25_Reset20 clock(
        .CLK(CLK),      // external 100 MHz clock
        .clkVGA(clkVGA),// internal clock 25 MHz (VGA only)
        .clk(clk),      // internal clock 6.25 MHz (everything else)
        .reset(clkRST), // reset signal ~20μs
        .phase(phase)
    );

    // reset PC during init & in [t+1] when GO load=1, both the load
    // and reset signal will shift high when the instruction is read
    // this mimics but is not the same as the iCE40 POR signal
    assign RST = clkRST | loadIO7;

    // CPU (ALU, A, D, PC)
    // ALU is combinational but A/D/PC are clocked
    // i.e. inputs are finalized at end of current cycle
    CPU cpu(
        .clk(clk),
        .inM(SRAM_OEX ? snap_data_run : inM), // OEX blocks SRAM_DATA so send cached data for M
        .instruction(inIO7 ? snap_instr : instruction), // prefer live instruction in boot mode
        .reset(RST),
        .outM(outM), // combinational
        .writeM(writeM), // combinational
        .addressM(addressM), // clocked (posedge)
        .pc(pc) // clocked (posedge)
    );

    // Memory (map + combinational routing only)
    // mux M input to CPU/ALU from I/O devices
    // mux load for I/O devices
    Memory mem(
        .address(addressM),
        .load(writeM),
        .inRAM(outRAM), // RAM (0-3583)
        .inIO0(outLED), // LED (4096)
        .inIO1(inIO1),  // BUT (4097)
        .inIO2(inIO2),  // [disabled] UART_TX (4098)
        .inIO3(inIO3),  // [disabled] UART_RX (4099)
        .inIO4(inIO4),  // unassigned
        .inIO5(inIO5),  // SRAM_A (4101)
        .inIO6(inIO6),  // SRAM_D (4102)
        .inIO7(inIO7),  // GO (4103)
        .inIO8(inIO8),  // unassigned
        .inIO9(inIO9),  // unassigned
        .inIOA(inIOA),  // unassigned
        .inIOB(inIOB),  // DEBUG0 (4107)
        .inIOC(inIOC),  // DEBUG1 (4108)
        .inIOD(inIOD),  // DEBUG2 (4109)
        .inIOE(inIOE),  // DEBUG3 (4110)
        .inIOF(inIOF),  // DEBUG4 (4111)
        .out(inM),
        .loadRAM(loadRAM),
        .loadIO0(loadIO0),
        .loadIO1(loadIO1), // unused
        .loadIO2(loadIO2), // disabled
        .loadIO3(loadIO3), // disabled
        .loadIO4(loadIO4), // unused
        .loadIO5(loadIO5),
        .loadIO6(loadIO6),
        .loadIO7(loadIO7),
        .loadIO8(loadIO8), 
        .loadIO9(loadIO9), 
        .loadIOA(loadIOA),
        .loadIOB(loadIOB),
        .loadIOC(loadIOC),
        .loadIOD(loadIOD),
        .loadIOE(loadIOE),
        .loadIOF(loadIOF)
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

    // SRAM_A/SRAM_D (4101/4102): 16 bit address/data register for 
    // K6R4016V1D (512KB SRAM @ 100 MHz read/write)

    // for SRAM_A arbitration just cycle through the phases
    // flags for read/write/output managed in SRAM_D
    // [phase 0:1 boot mode] CPU driven (boot.asm), new addr on load only
    // [phase 0:1 run mode] PC driven, updates every cycle
    // [phase 2:3] VGA controller drives address to inIO5 directly during mux
    // [phase 4:5] data read/write: update addr on load (SRAM_A or memory access)
    // [phase 6] feed data updates
    // [phase 7] reset for phase transition (if needed)

    // have to pipeline some values to break combinational loops
    // SRAM_ADDR updates now synced to negedge clk (CLK for multiple updates)
    reg [15:0] snap_outM=0, snap_data_run=0, snap_data_boot=0, snap_instr=0, sram_a=0;

    always @(posedge CLK) begin
        if (~clk & phase==1) begin
            // snapshot volatile CPU values after instruction fetch
            // i.e. values that are both combinational & influenced by I/O switches
            snap_outM <= outM; // TODO: unused again?
        end
        else if (~clk & phase==2) begin
            // snapshot instruction once fetched
            snap_instr <= instruction;
        end
        else if (~clk & phase==5) begin
            // snapshot data read/write value after SRAM_DATA updates
            // SRAM_D emits in phase 5, reflected on inIO6 in phase 6
            // then routes back to CPU/ALU for combinational update (if relevant/mux'd)
            // needs to be done within the OEX period so ALU doesn't double dip
            
            // FIXME: this can carry over to unrelated instructions
            // IDEA: cache data during posedge (requires additional read) & invalidate cache if address changes?
            snap_data_run <= outM;

            // boot mode updates
            if (loadIO5 & ~inIO7[0]) begin
                sram_a <= outM; // register SRAM_A updates
                snap_data_boot <= outM; // not updated every cycle in boot mode
            end
        end
        // remaining phases passively resolved during mux
    end

    // FIXME: sram_boot_test.asm PASSES in sim
    // FIXME: memory.asm PASSES in sim
    // FIXME: mult.asm PASSES in sim
    // FIXME: sram_go_test.asm PASSES in sim
    // FIXME: sram_run_test.asm BROKEN in sim
    
    // resolve SRAM_ADDR for current phase
    // [phase 0:1] fetch instruction according to boot/run mode driver(s)
    // [phase 2:3] driven by VGA controller
    // [phase 4:6] driven either by explicit SRAM_A writes (boot mode) or memory accesses (run mode)
    // [phase 7] reset during boot/run transition
    // because inIO5 routes to outM can't directly use outM for any inputs here
    assign inIO5 = RST ? 16'b0 :
                (~clk & (phase==2 | phase==3)) ? {3'b0, vga_addr} :
                (~clk & (phase>=4 & phase<=6) & ~inIO7[0] & loadIO5) ? snap_data_boot : // register new SRAM_A input
                (~clk & (phase>=4 & phase<=6) & ~inIO7[0]) ? sram_a : // use last SRAM_A in boot mode
                (~clk & (phase>=4 & phase<=6)) ? addressM : // last CPU address in run mode
                // default to instruction fetch (phase 0/1 + posedge)
                (~inIO7[0] ? sram_a : pc);

    // K6R4016V1D uses 18 bits but we address 16 LSB
    // [run mode only] go_sram_addr is offset by 0x10000 (data page)
    // this effectively adds 65535 (0xFFFF) to ~data~ addresses (VRAM, HEAP, etc)
    // data copied by boot.asm during boot mode will be read/written from/to first page
    assign SRAM_ADDR = (inIO7[0] & phase>=2) ? {2'b01, inIO5} : {2'b00, inIO5};

    SRAM_D sram_data (
        .CLK(CLK),         // external 100 MHz clock
        .clk(clk),         // internal 6.25 MHz clock
        .load(loadIO6),    // 1=write enabled, else read enabled
        .loadIO7(loadIO7), // 1=run mode starting
        .in(outM),         // input data (ignored on read)
        .out(inIO6),       // data out (instruction/VGA/RAM)
        .mode(inIO7),      // run_mode
        .DATA(SRAM_DATA),  // data line (inout)
        .CSX(SRAM_CSX),    // Chip Select NOT
        .OEX(SRAM_OEX),    // Output Enable NOT
        .WEX(SRAM_WEX),    // Write Enable NOT
        .phase(phase),
        .reset(RST)
    );

    // GO (4103): emit instruction from BRAM/SRAM
    // FUTURE: now relegated to run mode switch + routing instruction only?
    GO go(
        .clk(clk),
        .load(loadIO7), // trigger run mode
        .pc(pc), // no longer used (input)
        .rom_data(outROM), // instruction fetch (boot mode)
        .sram_addr_in(inIO5), // no longer used (input)
        .sram_data(inIO6), // instruction fetch (run mode) 
        .sram_addr_out(go_sram_addr), // no longer used (output)
        .instruction(instruction), // output instruction to CPU
        .out(inIO7) // output run mode
    );

    // TODO: VGA controller
    // VGA - Video graphics adapter 640x480 @ 50Hz
    wire [12:0] vga_addr;
    wire [15:0] vga_data;
    wire [3:0] VGA_R, VGA_G, VGA_B;
    wire VGA_HS, VGA_VS;
    VGA vga(
        .i_clk(clkVGA),
        .i_rst(RST),
        .o_addr(vga_addr),
        .i_data(vga_data),
        .o_vga_r(VGA_R),
        .o_vga_g(VGA_G),
        .o_vga_b(VGA_B),
        .o_vga_hs(VGA_HS),
        .o_vga_vs(VGA_VS)
    );

    // TODO: PS/2 Keyboard controller
    // PS2 - Keyboard controller
    wire [23:0] ps2_data;
    wire PS2_DATA, PS2_CLK; // TODO: placeholder
    PS2 ps2(
        .i_clk(clk),
        .i_rst(RST),
        .i_ps2_data(PS2_DATA),
        .i_ps2_clk(PS2_CLK),
        .o_data(ps2_data)
    );
    // Keyboard - PS2 to ASCII converter
    wire [15:0] _kbd;
    Keyboard kbd(
        .i_clk(clk),
        .i_rst(RST),
        .i_ps2_data(ps2_data),
        .o_data(_kbd)
    );

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