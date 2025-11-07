`timescale 10ns/1ns
`default_nettype none

module RTP_tb();
    reg clk = 0;
    always #2 clk = ~clk; // 25 MHz

    reg load = 0;
    reg [15:0] in = 0;
    wire [15:0] out;
    wire SDA, SCL;
    pullup(SDA);
    pullup(SCL);

    RTP rtp (
        .clk(clk),
        .SDA(SDA),
        .SCL(SCL),
        .in(in),
        .out(out),
        .load(load)
    );

    reg sda_drv = 0;   // drive low for data
    assign SDA = sda_drv ? 1'b0 : 1'bz;

    reg [7:0] slave_data = 8'h00;
    reg [2:0] bit_cnt = 0;
    reg sending = 0;

    wire rw = in[8]; // 0=write, 1=read
    wire busy = out[15];

    always @(negedge SCL ) begin
        begin
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
                // Capture write data (echo)
                if (!sending) slave_data <= in[7:0];
                sda_drv <= 0;
            end else begin
                sda_drv <= 0;
            end
        end
    end

    reg [31:0] n = 0;
    wire trigger;
    reg write = 1;
    assign trigger = (n == 20) || (n == 60);

    always @(posedge clk) begin
        if (trigger) begin
            load <= 1;
            in[7:0] <= $random;
            if (write == 1) begin
                in[8] <= 0; // first trigger write
                write <= 0;
            end else begin
                in[8] <= 1; // second trigger read
                write <= 1;
            end
        end else begin
            load <= 0;
        end
    end

    reg [15:0] out_cmp = 0;
    reg busy_cmp = 0;
    reg [7:0] last_wr = 0;
    reg [3:0] state_exp = 0;

    localparam [3:0]
        IDLE        = 4'd0,
        START_COND  = 4'd1,
        SEND_ADDR   = 4'd2,
        WRITE_BYTE  = 4'd3,
        READ_BYTE   = 4'd4,
        STOP_COND   = 4'd5;

    always @(posedge clk) begin
        case (state_exp)
            IDLE: begin
                if (load) begin
                    busy_cmp <= 1;
                    state_exp <= START_COND;
                    if (!in[8])
                        last_wr <= in[7:0];
                    else
                        out_cmp <= last_wr;
                end
            end

            START_COND:   state_exp <= SEND_ADDR;
            SEND_ADDR:    state_exp <= (in[8] ? READ_BYTE : WRITE_BYTE);
            WRITE_BYTE,
            READ_BYTE:    state_exp <= STOP_COND;
            STOP_COND: begin
                busy_cmp <= 0;
                state_exp <= IDLE;
            end
        endcase
    end

    // TODO: SDA/SCL cmp
    reg fail = 0;
    task check;
        #2
        if ((busy !== busy_cmp) || (out !== out_cmp)) begin
            $display("FAIL: clk=%b, load=%b, in=%02h, out=%02h, busy=%b",
                      clk, load, in, out, busy);
            fail = 1;
        end
    endtask

    initial begin
        $dumpfile("RTP_tb.vcd");
        $dumpvars(0, RTP_tb);

        $display("------------------------");
        $display("Testbench: RTP");

        for (n = 0; n < 200; n = n + 1) begin
            check();
        end

        if (fail == 0) $display("PASSED");
        $display("------------------------");
        $finish;
    end

endmodule
