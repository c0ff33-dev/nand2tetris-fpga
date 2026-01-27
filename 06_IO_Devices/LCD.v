/*
 * LCD communicates with ILI9341V LCD controller over 4 wire SPI.
 * 
 * When load=1 and in[8]=0 transmission of byte in[7:0] is initiated.
 * CSX is goes low (and stays low even when transmission is completed).
 * DCX is set to in[9]. The byte in[7:0] is sent to SDO bitwise together
 * with 8 clock signals on SCK. During transmission out[15] is 1.
 * After 16 clock cycles transmission is completed and out[15] is set to 0.
 * 
 * When load=1 and in[8]=1 CSX goes high and DCX=in[9] without transmission
 * of any bit.
 * 
 * When load16=1 transmission of word in[15:0] is initiated. CSX goes low
 * (and stays low even when transmission is completed). DCX is set to 1 (data).
 * After 32 clock cycles transmission is completed and out[15] is set to 0.
 *
 * 240x320x18 display, 256K colors (65K addressable)
 * DCX updates on the 7th negedge e.g. asserts on posedge of last command/data bit 
 * CSX must be driven low 1 cycle before SCK posedge and high no earlier than 8th SCK negedge
 *
 * In MOD-LCD2.8RTP the ILI9341V SDO (MISO) wire is not connected so we have no use for
 * an SDI wire on LCD and no way to read the response in any of the SPI commands that
 * return a response.
 *
 * Note: 2 cycles @ 25 MHz meets SCL pulse width requirements for write (twrh/twrl) 
 * but runs faster than total time (twc) - this is 1/2 speed compared to the SPI
 * implementation of the flash ROM which runs at the full 25 MHz.
 *
 * 320x240x16 = ~1.25m bits which requires minimum 2 cycles to transmit each bit (~1.5MB/s) however
 * Jack function call overheads are around ~600 cycles per 16 bits (~40 cycles/pixel, ~75KB/s) so even
 * in the best case the draw rate will max out at around ~0.5 fps. In general the performance cost  
 * to send the data over SPI contributes to but is a very minor part of the overall time taken.
 */

`default_nettype none
module LCD(
        input clk,          // clock 25 MHz
        input load,         // start send command/byte over SPI
        input load16,       // start send data (16 bits)
        input [15:0] in,    // data to be sent
        output [15:0] out,  // out[15]=1 if busy, else 0
        output DCX,         // SPI data/command not (0=command, 1=data)
        output CSX,         // SPI chip select not
        output SDO,         // SPI serial data out
        output SCK          // SPI serial clock
);

    // Put your code here:
    wire csx, dcx, busy, busy16, reset, reset16;
    wire [7:0] shiftOut, shiftOut16;
    wire [15:0] clkCount;

    // if in[8=0] and load=1 then csx=0 (drive CSX low, send byte)
    // if in[8=1] and load=1 then csx=1 (drive CSX high without sending byte)
    // init csx=1 to block any premture transactions
    // csx remains unchanged in either case until next load (cmd byte only)
    Bit cs (
        .clk(clk),
        .in(init ? in[8] : 1'b1),
        .load(init ? load : 1'b1),
        .out(csx)
    );

    // dcx gets set whenever load=1 regardless of CSX/byte transmission
    // if load16 dcx=1 (data), else dcx=in[9] (either)
    Bit dc (
        .clk(clk),
        .in(init ? (load16 ? 1'b1 : in[9]) : 1'b0),
        .load(init ? (load|load16) : 1'b1), // init dc=0
        .out(dcx)
    );

    // remaining registers are aligned to leading negedge
    // so shift can happen first then sample later in same cycle
    // busy bit is still set at load [t+1]

    // if in[8=0] and load=1 then busy=1 (transmission in progress)
    // load on new byte or reset when complete

    // run for 8 SCK/16 clk cycles
    Bit busyBit (
        .clk(clk),
        .in(reset ? 1'b0 : ~in[8]),
        .load(load | reset),
        .out(busy)
    );

    // run for 16 SCK/32 clk cycles
    // unconditionally busy for data loads
    Bit busy16Bit (
        .clk(clk),
        .in(reset16 ? 1'b0 : 1'b1),
        .load(load16 | reset16),
        .out(busy16)
    );
    
    // run SCK while busy
    // busy=1 cycle to set load, 16 cycles to shift 8 bits
    // busy16=1 cycle to set load, 32 cycles to shift 16 bits
    PC count(
        .clk(clk),
        .in(16'd0), // unused
        .load(1'd0), // unused
        .inc(busy | busy16), // inc while busy
        .reset(busy16 ? reset16 : reset), // cycle 0 to max clkCount
        .out(clkCount)
    );
    assign reset = (clkCount == 16'd15);
    assign reset16 = (clkCount == 16'd31);

    // circular buffer to enable duplex comms with slave where:
    // slave MSB >= master LSB (MISO)
    // master MSB >= slave LSB (MOSI)
    // init=0 before load, no shift on first cycle

    // if load=1 shiftReg gets cycled through SDO
    // if load16=1 shiftReg gets cycled through shiftReg16
    BitShift8L shiftReg (
        .clk(~clk), // posedge latch
        .in(init ? in[7:0] : 8'd0), // init on load
        .inLSB(1'b0), // no input, shiftReg will be empty after 8 shifts
        .load(init ? (load | load16) : 1'b1), // don't shift on load
        .shift(SCK & clkCount[0]), // once per negedge SCK (1/2 clk)
        .out(shiftOut) // available for sampling by posedge for SDO
    );

    // if load=1 shiftReg16 is ignored
    // if load16=1 shiftReg16 gets cycled through SDO
    //   and then after 8 shifts it will contain what shiftReg did at start
    BitShift8L shiftReg16 (
        .clk(~clk), // posedge latch
        .in(init ? in[15:8] : 8'd0), // init on load
        .inLSB(init ? shiftOut[7] : 1'b0), // shiftOutMSB into shiftOut16LSB
        .load(init ? load16 : 1'b1), // don't shift on load
        .shift(SCK & clkCount[0]), // once per negedge SCK (1/2 clk)
        .out(shiftOut16) // send shiftOut16 15:0 [15:8...7:0]
    );

    // generic init handler, should work with ice40 + yosys
    reg init = 0;
    always @(posedge clk) begin
        if (~init) begin
            init <= 1;
        end
    end

    assign CSX = init ? (load ? 1'b0 : csx) : 1'b1; // init CSX=1, drive low on load (CS setup time)
    assign SDO = init ? (busy16 ? (busy16 & shiftOut16[7]) : (busy & shiftOut[7])) : 1'b0; // MOSI (masterMSB to slaveLSB)
    assign SCK = init ? ((busy16 | busy) & clkCount[0]) : 1'b0; // run SCK while busy, start low, 1/2 clk speed
    assign DCX = init ? dcx : 1'b0;
    assign out = init ? {(busy16|busy),15'd0} : 1'b0; // out[15]=busy

endmodule
