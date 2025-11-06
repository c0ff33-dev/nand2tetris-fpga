`timescale 10ns/1ns
`default_nettype none

module RTP_tb();

    // -------------------------
    // Clock & reset
    // -------------------------
    reg clk = 0;
    reg reset_n = 0;

    always #2 clk=~clk; // 25 MHz

    // -------------------------
    // I2C master signals
    // -------------------------
    reg start = 0;
    reg rw = 0;                 // 0 = write, 1 = read
    reg [7:0] wr_data = 0;
    reg [6:0] dev_addr = 7'h50;
    wire [7:0] rd_data;
    wire busy;
    wire ack_error;
    wire sda, scl;

    // -------------------------
    // Pull-ups
    // -------------------------
    pullup(sda);
    pullup(scl);

    // -------------------------
    // Instantiate I2C master
    // -------------------------
    RTP rtp (
        .clk(clk),
        .reset_n(reset_n),
        .sda(sda),
        .scl(scl),
        .dev_addr(dev_addr),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .start(start),
        .rw(rw),
        .busy(busy),
        .ack_error(ack_error)
    );

    // -------------------------
    // Simple I2C slave model
    // -------------------------
    reg sda_drv = 0;      // drive low for ACK
    reg scl_drv = 0;      // hold low for clock stretch
    reg stretch = 0;      // clock stretch enable
    assign sda = sda_drv ? 1'b0 : 1'bz;
    assign scl = scl_drv ? 1'b0 : 1'bz;

    // Simple slave behavior: always ACK, optional stretch
    always @(posedge clk) begin
        if (stretch)
            scl_drv <= 1;
        else
            scl_drv <= 0;

        sda_drv <= 0; // always ACK
    end

    // -------------------------
    // Test stimulus
    // -------------------------
    reg [31:0] n = 0;
    wire trigger;
    assign trigger = (n == 10) || (n == 50) || (n == 100) || (n == 150); // start points

    always @(posedge clk) begin
        if (trigger) begin
            start <= 1;
            wr_data <= $random;
            rw <= $random % 2;
        end else begin
            start <= 0;
        end
    end

    // -------------------------
    // Expected outputs
    // -------------------------
    reg [7:0] rd_exp = 0;
    reg busy_exp = 0;
    reg ack_err_exp = 0;

    always @(posedge clk) begin
        if (start) begin
            busy_exp <= 1;
            ack_err_exp <= 0; // slave always ACKs
            if (rw) rd_exp <= 8'hA5; // arbitrary expected read value
        end else if (!busy) begin
            busy_exp <= 0;
        end
    end

    // -------------------------
    // Compare / fail signal
    // -------------------------
    reg fail = 0;

    task check;
        #1
        if ((busy !== busy_exp) || (ack_error !== ack_err_exp) || (rd_data !== rd_exp)) begin
            $display("FAIL: clk=%b, start=%b, rw=%b, wr_data=%02h, rd_data=%02h, busy=%b, ack_error=%b", 
                      clk, start, rw, wr_data, rd_data, busy, ack_error);
            fail = 1;
        end
    endtask

    // -------------------------
    // Main simulation
    // -------------------------
    initial begin
        $dumpfile("RTP_tb.vcd");
        $dumpvars(0, RTP_tb);

        $display("------------------------");
        $display("Testbench: RTP");

        // Release reset after a few cycles
        #5 reset_n = 1;

        // Run for N cycles
        for (n = 0; n < 200; n = n + 1) begin
            check();
        end

        if (fail == 0) $display("PASSED");
        $display("------------------------");
        $finish;
    end

endmodule
