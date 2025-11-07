`timescale 10ns/1ns
`default_nettype none

module RTP_tb();

    // -------------------------
    // Clock & reset
    // -------------------------
    reg clk = 0;
    reg reset_n = 0;
    always #2 clk = ~clk; // 25 MHz

    // -------------------------
    // I2C master signals
    // -------------------------
    reg load = 0;
    reg rw = 0;          // 0 = write, 1 = read
    reg [7:0] in = 0;
    wire [7:0] rd_data;
    wire busy;
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
        .in(in),
        .rd_data(rd_data),
        .load(load),
        .rw(rw),
        .busy(busy)
    );

    // -------------------------
    // Simple I2C slave model (echo last write)
    // -------------------------
    reg sda_drv = 0;   // drive low for data
    assign sda = sda_drv ? 1'b0 : 1'bz;

    reg [7:0] slave_data = 8'h00;
    reg [2:0] bit_cnt = 0;
    reg sending = 0;

    always @(negedge scl or negedge reset_n) begin
        if (!reset_n) begin
            sda_drv <= 0;
            bit_cnt <= 0;
            sending <= 0;
            slave_data <= 8'h00;
        end else begin
            if (busy && rw) begin
                // Send slave_data MSB first
                sda_drv <= slave_data[7 - bit_cnt];
                sending <= 1;
                bit_cnt <= bit_cnt + 1;
                if (bit_cnt == 7) begin
                    bit_cnt <= 0;
                    sending <= 0;
                end
            end else if (busy && !rw) begin
                // Capture write data (simple echo)
                if (!sending) slave_data <= in;
                sda_drv <= 0;
            end else begin
                sda_drv <= 0;
            end
        end
    end

    // -------------------------
    // Test stimulus
    // -------------------------
    reg [31:0] n = 0;
    wire trigger;
    reg write = 1;
    assign trigger = (n == 20) || (n == 60);

    always @(posedge clk) begin
        if (trigger) begin
            load <= 1;
            in <= $random;
            if (write == 1) begin
                rw <= 0; // first trigger write
                write <= 0;
            end else begin
                rw <= 1; // second trigger read
                write <= 1;
            end
        end else begin
            load <= 0;
        end
    end

    // -------------------------
    // Expected outputs
    // -------------------------
    reg [7:0] rd_exp = 0;
    reg busy_exp = 0;
    reg [7:0] last_wr = 0;

    always @(posedge clk) begin
        if (load) begin
            busy_exp <= 1;
            if (!rw)
                last_wr <= in; // remember last write
            else
                rd_exp <= last_wr;  // read should echo last write
        end else if (!busy) begin
            busy_exp <= 0;
        end
    end

    // -------------------------
    // Compare / fail signal
    // -------------------------
    reg fail = 0;

    task check;
        #2
        if ((busy !== busy_exp) || (rd_data !== rd_exp)) begin
            $display("FAIL: clk=%b, load=%b, rw=%b, in=%02h, rd_data=%02h, busy=%b", 
                      clk, load, rw, in, rd_data, busy);
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
