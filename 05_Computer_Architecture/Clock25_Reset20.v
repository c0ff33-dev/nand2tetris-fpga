/**
* Uses CLK of 100 MHz to generate:
* internal clock signal clk with 25 MHz and
* a reset signal of ~20μs duration
*/

`default_nettype none
module Clock25_Reset20( 
    input CLK,   // external clock 100 MHz    
    output clk,  // internal clock 25 MHz
    output reset // reset signal ~20μs
);

    // Put your code here:
    // assign CLK to a counter
    wire [15:0] psout;
    wire low;

    PC prescaler(
        .clk(CLK),
        .load(1'b0),
        .in(16'b0),
        .reset(1'b0),
        .inc(1'b1),
        .out(psout)
    );
    
    // scale down 100 MHz to 25 MHz (1/4)
    // PC itself is clocked so only one update per cycle
    // 2 bits = 2^2 = 4 cycles = 1/4 clock speed (25 MHz)
    assign clk = psout[1]; // demux the 2nd bit

    // Reset high for first 20μs @ 100 MHz
    // 1 cycle = 100 million / second or 10ns (ns = 1 billion / second)
    // 1000ns = 1μs (microsecond = 1 million / second)
    // therefore 20μs = 20 x 1000 / 10 = 2000 cycles
    assign low = (psout <= 16'd2000);

    // latch start so it doesn't continue resetting when PC overflows
    reg start = 0;
    always @(posedge CLK) begin
        if (!low && !start)
            start <= 1'b1;
    end

    // ...but still assign immediately
    assign reset = ~start;

endmodule
