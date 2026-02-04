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
    input clk,   // internal clock 25 MHz
    input clk50, // internal clock 50 MHz  
    input load,  // SRAM_DATA load
    input [15:0] in, // SRAM_DATA (write)
    output reg [15:0] out_pc, // instruction data
    output reg [15:0] out_data, // read data
    inout [15:0] DATA, // SRAM_DATA data line
    input [15:0] mode, // run_mode
    output CSX,  // Chip Select NOT
    output OEX,  // Output Enable NOT
    output WEX,   // Write Enable NOT,
    input phase  // phase signal for clk50 domain
);
    
    wire _load, dffLoad;
    wire [15:0] data, dataOut;
    reg phase;

    // in/load > out cycle remains in clk domain (25 MHz)
    // InOut interactions on the SRAM bus are on clk50 domain (50 MHz)
    
    // boot/run mode: there is still max 1 write per cycle
    // register outgoing data to clk domain
    // latch the write data on first cycle load is high
    Register reg_data (
        .clk(clk),
        .in(in),
        .load(_load),
        .out(data)
    );

    // boot/run mode: there is still max 1 write per cycle
    // emit the latched write data on 2nd cycle
    // repeat load in [t+1] for InOut (shared)
    DFF dff_load (
        .clk(clk),
        .in(load),
        .out(dffLoad)
    );

    // register control wires to clk domain (shared)
    reg csx=1; // chip select not (remains low after init)
    reg oex=0; // output enable not
    reg wex=1; // write enable not
    always @(posedge clk50) begin
        case (phase)
            // boot mode: no fetch / only writes, let 2nd phase override
            // run mode: fetch instruction 1st phase, data read/write 2nd phase
            0: begin
                // enable read
                oex <= 1'b0;
                wex <= 1'b1;
            end
            1: begin
                if (_load) begin
                    // enable write
                    oex <= 1'b1;
                    wex <= 1'b0;
                end
                else begin
                    // enable read
                    oex <= 1'b0;
                    wex <= 1'b1;
                end
            end
        endcase
    end

    // set and forget, doesn't need to be fast
    reg init = 0;
    always @(posedge clk) begin
        if (~init) begin
            init <= 1;
            csx <= 0;
        end
    end

    // bidirectional data bus (combinational)
    // disconnected (high impedence) when dir=0
    // SRAM_DATA PIN should never be driven from any other module!
    InOut io (
        .PIN(DATA), // inout=dataW when dir=1, else 16'bz
        .dataW(data), // outgoing data
        .dataR(dataOut), // incoming data
        .dir(dffLoad) // 1=write data to SRAM, else read
    );
    assign OEX = oex;
    assign WEX = wex;
    assign CSX = csx;

    assign _load = init ? load : 1'b0;

    // latch output to negedge (syncronous read, same as BRAM)
    // in run_mode dataOut is emitted every cycle
    always @(negedge clk50) begin
        case (phase)
            // boot mode:
            // do nothing during 1st phase
            // allow data writes during 2nd phase

            // run mode:
            // latch the pc fetch during 1st phase
            // latch the data read during 2nd phase if there was a write
            0: begin
                if (mode)
                    out_pc <= init ? dataOut : 16'bzzzzzzzzzzzzzzzz;
            end
            1: begin
                if (dffLoad)
                    out_data <= init ? dataOut : 16'bzzzzzzzzzzzzzzzz;
            end
        endcase
    end

endmodule