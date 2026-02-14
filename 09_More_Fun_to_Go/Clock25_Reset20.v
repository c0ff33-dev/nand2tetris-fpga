/**
* Uses CLK of 100 MHz to generate:
* internal clock signal clk with 25 MHz and
* a reset signal of ~20μs duration
*/

`default_nettype none
module Clock25_Reset20( 
    input CLK,    // external clock 100 MHz    
    output clkVGA,// internal clock 25 MHz (VGA only)
    output clk,   // internal clock 6.25 MHz (everything else)
    output reset, // reset signal ~20μs
    output reg [2:0] phase
);

    // assign CLK to a counter
    wire [15:0] psout;
    wire low;

    // 100 MHz counter
    PC prescaler(
        .clk(CLK),
        .load(1'b0),
        .in(16'b0),
        .reset(_reset),
        .inc(1'b1),
        .out(psout)
    );

    // scale down 100 MHz to 25 MHz (1/4)
    // PC itself is clocked so only one update per cycle
    assign clkVGA = psout[1]; // demux 2nd LSB (1/4) = 25 MHz (40ns)
    assign clk = psout[3]; // demux 4th LSB (1/16) = 6.25 MHz (160ns)

    // Reset high for first 20μs @ 100 MHz
    // 1 cycle = 100 million / second or 10ns (ns = 1 billion / second)
    // 1000ns = 1μs (microsecond = 1 million / second)
    // therefore 20μs = 20 x 1000 / 10 = 2000 cycles
    assign low = (psout <= 16'd2000);

    // latch start so it doesn't continue resetting when PC overflows
    reg start = 0;
    reg _reset = 0;
    always @(posedge CLK) begin
        if (!low && !start) begin
            start <= 1'b1;
            _reset <= 1'b1; // sync prescaler as well
        end else
            _reset <= 1'b0;
    end

    // ...but still assign immediately
    assign reset = ~start;

    // 8 phase generator
    // CLK @ 100 MHz = 10ns per tick
    // 8 phases per 6.25 MHz clk edge
    always @(posedge CLK)
        if (!low | !start)
            phase <= 3'd0;
        else
            phase <= phase + 3'd1; // phase 0-7
endmodule
