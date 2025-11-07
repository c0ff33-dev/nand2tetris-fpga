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

    // Slave: return read data to master
    reg tb_sda_drv = 0;   // drive low for data, else release (high z)
    assign SDA = tb_sda_drv ? 1'b0 : 1'bz;

    reg [7:0] tb_slv_data = 8'h00;
    reg [2:0] tb_slv_bitcnt = 0;
    reg tb_slv_sending = 0;

    wire tb_rw_w = in[8]; // 0=write, 1=read, in is stable in sim only
    wire tb_busy = out[15];

    always @(negedge SCL ) begin
        begin
            if (tb_busy && !tb_rw_w) begin
                // on write populate output buffer
                if (!tb_slv_sending) tb_slv_data <= 8'hDE;
                tb_sda_drv <= 0; // SDA low
            end
            else if (tb_busy && tb_rw_w) begin
                // Send tb_slv_data MSB first
                tb_sda_drv <= tb_slv_data[7 - tb_slv_bitcnt];
                tb_slv_sending <= 1;
                tb_slv_bitcnt <= tb_slv_bitcnt + 1;
                if (tb_slv_bitcnt == 7) begin
                    tb_slv_bitcnt <= 0;
                    tb_slv_sending <= 0;
                    // on completion of first read set next byte
                    tb_slv_data <= 8'hAD;
                end
            end else
                tb_sda_drv <= 0;
        end
    end

    // Master: trigger write command followed by read command
    reg [31:0] tb_n = 0;
    reg tb_write = 1;
    wire trigger = (tb_n == 20) || (tb_n == 2000);

    always @(posedge clk) begin
        if (trigger) begin
            load <= 1;
            in[7:0] <= $random;
            if (tb_write == 1) begin
                in[8] <= 0; // first trigger write
                tb_write <= 0;
            end else begin
                in[8] <= 1; // second trigger read
                tb_write <= 1;
            end
        end else begin
            load <= 0;
        end
    end

    // Testbench state machine
    reg [15:0] out_cmp = 0;
    reg busy_cmp = 0;

    localparam [3:0]
        IDLE        = 4'd0,
        START_COND  = 4'd1,
        SEND_ADDR   = 4'd2,
        WRITE_BYTE  = 4'd3,   
        READ_BYTE   = 4'd4,
        READ_BYTE2  = 4'd5;
        // STOP_COND   = 4'd6;

    // SDA/SCL comparators
    localparam TB_DIVIDER = 15; // 400 KHz (fast mode)
    reg [9:0] tb_clk_cnt = 0;
    reg tb_tick = 0;
    reg sda_cmp = 1;
    reg scl_cmp = 1;
    reg [3:0] tb_state = IDLE;
    reg [1:0] tb_phase = 0;
    reg [3:0] tb_bit_cnt = 0;
    reg [7:0] tb_shiftreg = 0;
    reg tb_rw = 0;

    // master data
    reg [7:0] tb_mdata [0:4];  // 6 elements x 8 bits
    reg [2:0] tb_midx = 0;

    initial begin
        tb_mdata[0] = 8'h90; // tb_write cmd
        tb_mdata[1] = 8'hFF; // response placeholder
        tb_mdata[2] = 8'h91; // read cmd
        tb_mdata[3] = 8'hDE; // read bytes
        tb_mdata[4] = 8'hAD;
    end

    // Generate tick
    always @(posedge clk) begin
        if (busy_cmp) begin
            if (tb_clk_cnt == TB_DIVIDER - 1) begin
                tb_clk_cnt <= 0;
                tb_tick <= 1'b1;
            end else begin
                tb_clk_cnt <= tb_clk_cnt + 1;
                tb_tick <= 1'b0;
            end
        end else begin
            tb_clk_cnt <= 0;
            tb_tick <= 1'b0;
        end
    end

    always @(posedge clk) begin
        case (tb_state)
            IDLE: begin
                sda_cmp <= 1; // both high at idle
                scl_cmp <= 1;
                tb_phase <= 0;
                if (load) begin
                    busy_cmp <= 1; // tb_busy from load
                    out_cmp <= 16'h8000;
                    tb_rw <= tb_rw;   // read tb_rw from in[8]
                    tb_state <= START_COND;
                    tb_shiftreg <= tb_mdata[tb_midx]; // update shift on start
                    tb_midx <= tb_midx + 1;
                end
            end

            START_COND: begin
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            sda_cmp <= 0;   // SDA low
                            scl_cmp <= 1;   // SCL high
                            tb_phase <= 1;
                        end
                        1: begin
                            tb_bit_cnt <= 7;
                            tb_phase <= 0;
                            tb_state <= SEND_ADDR;
                        end
                        default: tb_phase <= 0;
                    endcase
                end
            end

            SEND_ADDR: begin
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                       // SCL low
                            sda_cmp <= tb_shiftreg[tb_bit_cnt]; // set data
                            tb_phase <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high
                            tb_phase <= 2;
                        end
                        2: begin
                            scl_cmp <= 0;                       // SCL low
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 1;                   // slave ACK (release)
                                tb_phase <= 3;
                            end else begin
                                tb_bit_cnt <= tb_bit_cnt - 1;
                                tb_phase <= 0;
                            end
                        end
                        3: begin
                            scl_cmp <= 1;                       // SCL high for ACK
                            tb_shiftreg <= tb_mdata[tb_midx];   // update shift before read/write
                            tb_midx <= tb_midx + 1;
                            tb_bit_cnt <= 7;
                            if (tb_rw) begin
                                tb_state <= READ_BYTE;
                            end else begin
                                tb_state <= WRITE_BYTE;
                            end
                            tb_phase <= 0;
                        end
                    endcase
                end
            end

            WRITE_BYTE: begin
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                       // SCL low
                            sda_cmp <= tb_shiftreg[tb_bit_cnt]; // set data
                            tb_phase <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high
                            tb_phase <= 2;
                        end
                        2: begin
                            scl_cmp <= 0;                       // SCL low
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 1;                   // release for ACK
                                tb_phase <= 3;
                            end else begin
                                tb_bit_cnt <= tb_bit_cnt - 1;
                                tb_phase <= 0;
                            end
                        end
                        3: begin
                            scl_cmp <= 1;                       // SCL high for ACK
                            tb_state <= IDLE;
                            tb_phase <= 0;
                            out_cmp <= 16'hFF;                  // response byte shifted in, done
                        end
                    endcase
                end
            end

            READ_BYTE: begin
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                       // SCL low
                            sda_cmp <= tb_shiftreg[tb_bit_cnt]; // set data
                            tb_phase <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high
                            tb_phase <= 2;
                        end
                        2: begin
                            scl_cmp <= 0;                       // SCL low
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                   // drive low for NACK
                                tb_phase <= 3;
                            end else begin
                                tb_bit_cnt <= tb_bit_cnt - 1;
                                tb_phase <= 0;
                            end
                        end
                        3: begin
                            scl_cmp <= 1;                       // SCL high for NACK
                            tb_state <= READ_BYTE2;
                            tb_phase <= 0;

                            tb_shiftreg <= tb_mdata[tb_midx];   // update shift/out before 2nd read
                            tb_midx <= tb_midx + 1;
                            out_cmp <= 16'h80DE;                // first byte shifted in, still tb_busy
                            tb_bit_cnt <= 7;
                        end
                    endcase
                end
            end

            READ_BYTE2: begin
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                       // SCL low
                            sda_cmp <= tb_shiftreg[tb_bit_cnt]; // set data
                            tb_phase <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high
                            tb_phase <= 2;
                        end
                        2: begin
                            scl_cmp <= 0;                       // SCL low
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                   // drive low for NACK
                                tb_phase <= 3;
                            end else begin
                                tb_bit_cnt <= tb_bit_cnt - 1;
                                tb_phase <= 0;
                            end
                        end
                        3: begin
                            scl_cmp <= 1;                       // SCL high for NACK
                            tb_state <= IDLE;
                            tb_phase <= 0;
                            out_cmp <= 16'hDEAD;                // 2nd byte shifted, done
                        end
                    endcase
                end
            end

            // STOP_COND: begin
            //     if (tb_tick) begin
            //         case (tb_phase)
            //             0: begin
            //                 sda_cmp <= 0;                       // SDA low
            //                 scl_cmp <= 1;                       // SCL high
            //                 tb_phase <= 1;
            //             end
            //             1: begin
            //                 sda_cmp <= 1;                       // SDA high (release)
            //                 busy_cmp <= 0;
            //                 tb_state <= IDLE;
            //                 tb_phase <= 0;
            //             end
            //             default: tb_phase <= 0;
            //         endcase
            //     end
            // end
        endcase
    end

    reg fail = 0;
    task check;
        #2
        if ((tb_busy != busy_cmp) || (out !== out_cmp) || (SDA != sda_cmp) || (SCL != scl_cmp)) begin
            $display("FAIL: clk=%b, load=%b, in=%02h, out=%02h, tb_busy=%b",
                      clk, load, in, out, tb_busy, SDA, SCL);
            fail = 1;
        end
    endtask

    initial begin
        $dumpfile("RTP_tb.vcd");
        $dumpvars(0, RTP_tb);

        $display("------------------------");
        $display("Testbench: RTP");

        for (tb_n = 0; tb_n < 5000; tb_n = tb_n + 1) begin
            check();
        end

        if (fail == 0) $display("PASSED");
        $display("------------------------");
        $finish;
    end

endmodule