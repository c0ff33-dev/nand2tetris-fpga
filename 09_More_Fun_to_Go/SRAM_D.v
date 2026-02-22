/**
 * SRAM controller for K6R4016V1D:
 * If load[t] == 1 then out[t+1] = in[t]
 *                      OEX[t+1] = 1
 *                      WEX[t+1] = 0
 *                      DATA[t+1] = in[t] (DATA is configured as output)
 * At any other time:
 *   out = DATA (DATA is configured as input)
 *   WEX=1, OEX=0
 *   CSX=1 (disabled) during init then 0 (enabled) afterwards
 *
 * K6R4016V1D read/write latency is 5-10ns so at 50 MHz bus should still
 * be stable before it is sampled (same cycle as emitted or [t+1] 
 * from initial load=1 signal).
 */

`default_nettype none
module SRAM_D(
    input CLK, // external 100 MHz clock
    input clk, // internal 6.25 MHz clock
    input load,  // SRAM_DATA load
    input loadIO7, // run mode starting
    input [15:0] in, // SRAM_DATA (write)
    output [15:0] out, // data out (instruction/VGA/RAM) 
    inout [15:0] DATA, // SRAM_DATA data line
    input [15:0] mode, // run_mode
    output CSX,  // Chip Select NOT
    output OEX,  // Output Enable NOT
    output WEX,  // Write Enable NOT,
    input [2:0] phase,
    input reset
);
    // removed input/output registers/syncronization to be fully combinational
    wire _load;
    wire [15:0] dataOut;
    
    // control wires 
    // [phase 0:1] run mode: enable read (instruction fetch)
    // [phase 0:1] boot mode: do nothing, data read/write in SRAM phase
    // [phase 2:3] vga: enable read (VRAM)
    // [phase 4:5] enable data write to SRAM on load, else read
    // [phase 6:7] <unused>
    // enable write flag in relevant phase else default to read
    // only update values in clk negedge to syncronize with BRAM/ROM updates
    assign OEX = ((~clk & (phase==4 | phase==5) & _load) ? 1'b1 : 1'b0);
    assign WEX = ((~clk & (phase==4 | phase==5) & _load) ? 1'b0 : 1'b1);

    // set and forget
    reg init = 0;
    reg csx=1; // chip select not (remains low after init)
    always @(posedge CLK) begin
        if (~init) begin
            init <= 1;
            csx <= 0;
        end
    end
    assign CSX = csx;

    // bidirectional data bus (combinational)
    // disconnected (high impedence) when dir=0
    // SRAM_DATA PIN should never be driven from any other module!
    InOut io (
        .PIN(DATA), // inout=dataW when dir=1, else 16'bz
        .dataW(in), // outgoing data
        .dataR(dataOut), // incoming data
        .dir(_load & ~WEX) // 1=write data to SRAM, else read
    );

    assign _load = init ? load : 1'b0;

    // output wires
    // [phase 0:1 run mode]: latch the data read during data phase if there was a write
    // [phase 0:1 boot mode]: do nothing, [run mode]: latch fetched instruction
    // [phase 2:3] emit VRAM data (passive/every cycle)
    // [phase 4:5 boot mode]: latch new instruction if there was a write   
    // [phase 4:5 run mode]: latch new data if there was a write
    // [phase 6:7] <do nothing>
    reg [15:0] _out;

    // only update values in clk negedge to syncronize with BRAM/ROM updates (CLK for multiple updates)
    // +1 phase latch latency vs when collected 
    always @(posedge CLK) begin
        if (~clk & (phase==1 & (mode | loadIO7)))
            // emit instruction every negedge in run mode
            // and the preceding negedge when transitioning to run mode
            _out <= init ? dataOut : 16'bz;
        else if (phase==3)
            // emit VGA on both edges
            _out <= init ? dataOut : 16'bz;
        else if (phase==5)
            // emit data every negedge for regular output
            // emit new data during posedge for caching
            _out <= init ? dataOut : 16'bz;
    end

    // inIO6 consumers responsible for checking phase
    assign out = _out;

endmodule