`default_nettype none
module RAM3584_tb();

    // IN,OUT
    reg clk=1;
    reg [15:0] in;
    reg [11:0] address;
    reg load;
    wire [15:0] out;

    // Part
    RAM3584 RAM3584(
        .clk(clk),
        .address(address),
        .in(in),
        .load(load),
        .out(out)
    );

    // Simulate
    always #1 clk=~clk; // no time scale
    always @(posedge clk) begin
        in <= $random;
        address <= (n<3584)?n:n-3584;
        load <= (n<3584);
    end

    // Compare
    reg [15:0] regRAM [0:3583];
    reg [15:0] out_cmp;
    always @(posedge clk)
        if (load) regRAM[address[11:0]] <= in;
    always @(negedge clk)
        out_cmp <= regRAM[address[11:0]];
    
    reg fail = 0;
    reg [15:0] n = 0;
    task check;
    begin
        @(negedge clk);
        #1;
        if (out != out_cmp) begin
            $display("FAIL: clk=%1b, address=%12b, in=%16b, load=%1b, out=%16b",clk,address,in,load,out);
            fail=1;
        end
    end
    endtask
      
    initial begin
        $dumpfile("RAM3584_tb.vcd");
        $dumpvars(0, RAM3584_tb);
        
        $display("------------------------");
        $display("Test bench: RAM3584");

        for (n=0; n<2*3584;n=n+1) 
            check();
        
        if (fail==0) $display("passed");
        $display("------------------------");
        $finish;
    end

endmodule
