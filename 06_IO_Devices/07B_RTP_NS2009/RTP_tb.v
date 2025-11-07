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
    assign trigger = (n == 20) || (n == 2000);

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
    reg [3:0] state_cmp = 0;

    localparam [3:0]
        IDLE        = 4'd0,
        START_COND  = 4'd1,
        SEND_ADDR   = 4'd2,
        WRITE_BYTE  = 4'd3,   
        READ_BYTE   = 4'd4,
        READ_BYTE2  = 4'd5,
        STOP_COND   = 4'd6;

    always @(posedge clk) begin
        case (state_cmp)
            IDLE: begin
                if (load) begin
                    busy_cmp <= 1;
                    state_cmp <= START_COND;
                    if (!in[8])
                        last_wr <= in[7:0];
                    else
                        out_cmp <= last_wr;
                end
            end

            START_COND:   state_cmp <= SEND_ADDR;
            SEND_ADDR:    state_cmp <= (in[8] ? READ_BYTE : WRITE_BYTE);
            WRITE_BYTE,
            READ_BYTE:    state_cmp <= STOP_COND;
            STOP_COND: begin
                busy_cmp <= 0;
                state_cmp <= IDLE;
            end
        endcase
    end

    // SDA/SCL comparators - track expected behavior based on RTP implementation
    localparam DIVIDER = 15; // 400 KHz (fast mode)
    reg [9:0] clk_cnt_cmp = 0;
    reg tick_cmp = 0;
    reg sda_cmp = 1;
    reg scl_cmp = 1;
    reg [3:0] state_cmp = IDLE;
    reg [1:0] phase_cmp = 0;
    reg [3:0] bit_cnt_cmp = 0;
    reg [7:0] shift_reg_cmp = 0;
    reg rw_cmp = 0;

    // Generate tick
    always @(posedge clk) begin
        if (busy_cmp) begin
            if (clk_cnt_cmp == DIVIDER - 1) begin
                clk_cnt_cmp <= 0;
                tick_cmp <= 1'b1;
            end else begin
                clk_cnt_cmp <= clk_cnt_cmp + 1;
                tick_cmp <= 1'b0;
            end
        end else begin
            clk_cnt_cmp <= 0;
            tick_cmp <= 1'b0;
        end
    end

    // State machine for SDA/SCL prediction
    always @(posedge clk) begin
        case (state_cmp)
            IDLE: begin
                sda_cmp <= 1;
                scl_cmp <= 1;
                phase_cmp <= 0;
                if (load) begin
                    busy_cmp <= 1;
                    shift_reg_cmp <= {7'h48, 1'b0};
                    rw_cmp <= in[8];
                    state_cmp <= START_COND;
                end
            end

            START_COND: begin
                if (tick_cmp) begin
                    case (phase_cmp)
                        0: begin
                            sda_cmp <= 0;   // SDA low
                            scl_cmp <= 1;   // SCL high
                            phase_cmp <= 1;
                        end
                        1: begin
                            bit_cnt_cmp <= 7;
                            phase_cmp <= 0;
                            state_cmp <= SEND_ADDR;
                        end
                        default: phase_cmp <= 0;
                    endcase
                end
            end

            SEND_ADDR: begin
                if (tick_cmp) begin
                    case (phase_cmp)
                        0: begin
                            scl_cmp <= 0;                       // SCL low
                            sda_cmp <= shift_reg_cmp[bit_cnt_cmp]; // set data
                            phase_cmp <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high
                            phase_cmp <= 2;
                        end
                        2: begin
                            scl_cmp <= 0;                       // SCL low
                            if (bit_cnt_cmp == 0) begin
                                sda_cmp <= 1;                   // release for ACK
                                phase_cmp <= 3;
                            end else begin
                                bit_cnt_cmp <= bit_cnt_cmp - 1;
                                phase_cmp <= 0;
                            end
                        end
                        3: begin
                            scl_cmp <= 1;                       // SCL high for ACK
                            if (rw_cmp) begin
                                bit_cnt_cmp <= 7;
                                state_cmp <= READ_BYTE;
                            end else begin
                                bit_cnt_cmp <= 7;
                                shift_reg_cmp <= last_wr;
                                state_cmp <= WRITE_BYTE;
                            end
                            phase_cmp <= 0;
                        end
                    endcase
                end
            end

            WRITE_BYTE: begin
                if (tick_cmp) begin
                    case (phase_cmp)
                        0: begin
                            scl_cmp <= 0;                       // SCL low
                            sda_cmp <= shift_reg_cmp[bit_cnt_cmp]; // set data
                            phase_cmp <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high
                            phase_cmp <= 2;
                        end
                        2: begin
                            scl_cmp <= 0;                       // SCL low
                            if (bit_cnt_cmp == 0) begin
                                sda_cmp <= 1;                   // release for ACK
                                phase_cmp <= 3;
                            end else begin
                                bit_cnt_cmp <= bit_cnt_cmp - 1;
                                phase_cmp <= 0;
                            end
                        end
                        3: begin
                            scl_cmp <= 1;                       // SCL high for ACK
                            state_cmp <= STOP_COND;
                            phase_cmp <= 0;
                        end
                    endcase
                end
            end

            READ_BYTE: begin
                if (tick_cmp) begin
                    case (phase_cmp)
                        0: begin
                            scl_cmp <= 0;                       // SCL low
                            sda_cmp <= 1;                       // release SDA
                            phase_cmp <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high
                            phase_cmp <= 2;
                        end
                        2: begin
                            scl_cmp <= 0;                       // SCL low
                            if (bit_cnt_cmp == 0) begin
                                sda_cmp <= 0;                   // drive low for NACK
                                phase_cmp <= 3;
                            end else begin
                                bit_cnt_cmp <= bit_cnt_cmp - 1;
                                phase_cmp <= 0;
                            end
                        end
                        3: begin
                            scl_cmp <= 1;                       // SCL high for NACK
                            state_cmp <= READ_BYTE2;
                            phase_cmp <= 0;
                        end
                    endcase
                end
            end

            READ_BYTE2: begin
                if (tick_cmp) begin
                    case (phase_cmp)
                        0: begin
                            scl_cmp <= 0;                       // SCL low
                            sda_cmp <= 1;                       // release SDA
                            phase_cmp <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high
                            phase_cmp <= 2;
                        end
                        2: begin
                            scl_cmp <= 0;                       // SCL low
                            if (bit_cnt_cmp == 0) begin
                                sda_cmp <= 0;                   // drive low for NACK
                                phase_cmp <= 3;
                            end else begin
                                bit_cnt_cmp <= bit_cnt_cmp - 1;
                                phase_cmp <= 0;
                            end
                        end
                        3: begin
                            scl_cmp <= 1;                       // SCL high for NACK
                            state_cmp <= STOP_COND;
                            phase_cmp <= 0;
                        end
                    endcase
                end
            end

            STOP_COND: begin
                if (tick_cmp) begin
                    case (phase_cmp)
                        0: begin
                            sda_cmp <= 0;                       // SDA low
                            scl_cmp <= 1;                       // SCL high
                            phase_cmp <= 1;
                        end
                        1: begin
                            sda_cmp <= 1;                       // SDA high (release)
                            busy_cmp <= 0;
                            state_cmp <= IDLE;
                            phase_cmp <= 0;
                        end
                        default: phase_cmp <= 0;
                    endcase
                end
            end
        endcase
    end

    reg fail = 0;
    task check;
        #2
        if ((busy != busy_cmp) || (out !== out_cmp) || (SDA != sda_cmp) || (SCL != scl_cmp)) begin
            $display("FAIL: clk=%b, load=%b, in=%02h, out=%02h, busy=%b",
                      clk, load, in, out, busy, SDA, SCL);
            fail = 1;
        end
    endtask

    initial begin
        $dumpfile("RTP_tb.vcd");
        $dumpvars(0, RTP_tb);

        $display("------------------------");
        $display("Testbench: RTP");

        for (n = 0; n < 5000; n = n + 1) begin
            check();
        end

        if (fail == 0) $display("PASSED");
        $display("------------------------");
        $finish;
    end

endmodule
