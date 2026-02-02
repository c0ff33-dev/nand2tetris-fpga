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

 // TODO: in theory if BRAM and SRAM are fast enough can squeeze 2 R/W cycles per clk phase
 
`default_nettype none
module SRAM_D(
    input CLK,   // external clock 100 MHz
    input clk,   // internal clock 25 MHz    
    input load,  // SRAM_DATA load
    input load2, // SCREEN load
    input [15:0] in, // SRAM_DATA (write)
    input [15:0] in2, // SCREEN (write)
    output reg [15:0] out, // SRAM_DATA (read)
    output reg [15:0] out2, // SCREEN (read)
    inout [15:0] DATA, // SRAM_DATA data line
    input [15:0] mode, // run_mode
    output CSX,  // Chip Select NOT
    output OEX,  // Output Enable NOT
    output WEX   // Write Enable NOT
);
    
    wire _load, _load2, dffLoad, clk2;
    wire [15:0] _dataOut, data, data2, dataOut;
    wire [15:0] psout;
    reg phase;

    // in/load > out cycle remains in clk domain (25 MHz)
    // InOut interactions on the SRAM bus are on clk2 domain (50 MHz)
    
    // register outgoing data to clk domain
    // latch the write data on first cycle load is high
    Register reg_data (
        .clk(clk),
        .in(in),
        .load(_load),
        .out(data)
    );

    Register reg_data2 (
        .clk(clk),
        .in(in2),
        .load(_load2),
        .out(data2)
    );

    // emit the latched write data on 2nd cycle
    // repeat load in [t+1] for InOut (shared)
    DFF dff_load (
        .clk(clk),
        .in(load | load2),
        .out(dffLoad)
    );

    // assign CLK to a counter
    PC prescaler(
        .clk(CLK),
        .load(1'b0),
        .in(16'b0),
        .reset(1'b0),
        .inc(1'b1),
        .out(psout)
    );
    
    // scale down 100 MHz to 50 MHz (1/2)
    assign clk2 = psout[0]; // demux LSB

    // register control wires to clk domain (shared)
    reg csx=1; // chip select not (remains low after init)
    reg oex=0; // output enable not
    reg wex=1; // write enable not
    always @(posedge clk2) begin
        if (_load | _load2) begin
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

    // set and forget, doesn't need to be fast
    reg init = 0;
    always @(posedge clk) begin
        if (~init) begin
            init <= 1;
            csx <= 0;
        end
    end

    // TODO: model isn't yet clear
    //   - needs dual input for SCREEN and SRAM_DATA?
    //   - needs dual output for SCREEN and SRAM_DATA?
    //   - how to alternate the data bus usage?
    //   - how to alternate the SRAM_A address?
    //   - can leave stack on BRAM and move heap over to SRAM as well?

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
    assign _load2 = init ? load2 : 1'b0;

    // latch output to negedge (syncronous read, same as BRAM)
    // in run_mode dataOut is emitted every cycle
    always @(negedge clk2) begin
        phase <= init ? ~phase : 1'b0;
        case (phase)
            0: begin
                if (dffLoad | mode)
                    out <= init ? dataOut : 16'bzzzzzzzzzzzzzzzz;
                else
                    out2 <= init ? out : 16'bzzzzzzzzzzzzzz
            end
            1: begin
                if (dffLoad | mode)
                    out2 <= init ? dataOut : 16'bzzzzzzzzzzzzzzzz;
                else
                    out2 <= init ? out2 : 16'bzzzzzzzzzzzzzz
            end
        endcase
    end


    
endmodule
