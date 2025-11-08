`timescale 10ns/1ns
`default_nettype none

module RTP_tb();
    reg tb_clk = 0;
    always #2 tb_clk = ~tb_clk; // 25 MHz

    // device under test
    reg tb_load = 0;
    reg [15:0] tb_in = 0; // this is a reg in sim only!
    wire [15:0] tb_out;
    wire tb_SDA, tb_SCL;
    pullup(tb_SDA);
    pullup(tb_SCL);

    RTP rtp (
        .clk(tb_clk),
        .SDA(tb_SDA),
        .SCL(tb_SCL),
        .in(tb_in),
        .out(tb_out),
        .load(tb_load)
    );

    // slave: drive SDA to return data to master
    reg tb_sda_drv = 0;   // drive low for data when set, else release (high z)
    assign tb_SDA = tb_sda_drv ? 1'b0 : 1'bz;

    reg [7:0] tb_slv_data = 0;
    reg [2:0] tb_slv_bitcnt = 0;
    reg tb_slv_sending = 0;

    wire tb_busy = tb_out[15];

    always @(negedge tb_SCL ) begin
        begin
            if (tb_busy && !tb_in[8]) begin
                // on write populate output buffer
                if (!tb_slv_sending) tb_slv_data <= tb_mdata[3];
                tb_sda_drv <= 0; // release SDA
            end
            else if (tb_busy && tb_in[8]) begin
                // Send tb_slv_data MSB first
                tb_sda_drv <= tb_slv_data[7 - tb_slv_bitcnt];
                tb_slv_sending <= 1;
                tb_slv_bitcnt <= tb_slv_bitcnt + 1;
                if (tb_slv_bitcnt == 7) begin
                    tb_slv_bitcnt <= 0;
                    tb_slv_sending <= 0;
                    // on completion of first read set next byte
                    tb_slv_data <= tb_mdata[4];
                end
            end else
                tb_sda_drv <= 0; // release SDA
        end
    end

    // master: trigger write command followed by read command
    reg [31:0] tb_n = 0;
    reg tb_write = 1;
    wire trigger = (tb_n == 20) || (tb_n == 1500);

    always @(posedge tb_clk) begin
        if (trigger) begin
            tb_load <= 1;
            tb_in[7:0] <= $random;
            if (tb_write == 1) begin
                tb_in[8] <= 0; // first trigger write
                tb_write <= 0;
            end else begin
                tb_in[8] <= 1; // second trigger read
                tb_write <= 1;
            end
        end else begin
            tb_load <= 0;
        end
    end

    // testbench state machine
    reg [15:0] out_cmp = 0;
    reg busy_cmp = 0;

    localparam [3:0]
        IDLE        = 4'd0,
        START_COND  = 4'd1,
        SEND_ADDR   = 4'd2,
        WRITE_BYTE  = 4'd3,   
        READ_BYTE   = 4'd4,
        READ_BYTE2  = 4'd5;

    // 400 KHz (fast mode) = 25_000_000 / (400_000 * ticks);
    localparam TB_DIVIDER = 20; // max 3 ticks per SCL cycle
    reg [9:0] tb_clk_cnt = 0;
    reg tb_tick = 0;
    reg sda_cmp = 1;
    reg scl_cmp = 1;
    reg [3:0] tb_state = IDLE;
    reg [1:0] tb_phase = 0;
    reg [3:0] tb_bit_cnt = 0;
    reg [7:0] tb_shiftreg = 0;

    // input/output data
    reg [7:0] tb_mdata [0:4];  // 4 elements x 8 bits
    reg [2:0] tb_midx = 0;

    initial begin
        tb_mdata[0] = 8'h90;   // write cmd (no response)
        tb_mdata[1] = 8'h91;   // read cmd
        tb_mdata[2] = $random; // read bytes
        tb_mdata[3] = $random;
    end

    // generate tick
    always @(posedge tb_clk) begin
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

    // need 9 SCL cycles per byte (8 data + ACK/NACK)
    // bit processing is pretty much the same except for ACK/NACK and output
    always @(posedge tb_clk) begin
        case (tb_state)
            IDLE: begin
                sda_cmp <= 1; // both high at idle
                scl_cmp <= 1;
                tb_phase <= 0;
                if (tb_load) begin
                    // busy from load [t+1]
                    busy_cmp <= 1; 
                    out_cmp <= 16'h8000;
                    tb_state <= START_COND;

                    // update shift on load
                    tb_shiftreg <= tb_mdata[tb_midx];
                    tb_midx <= tb_midx + 1;
                    tb_bit_cnt <= 8;
                end
            end

            START_COND: begin
                if (tb_tick) begin
                    // START bit
                    scl_cmp <= 1;   // SCL high
                    sda_cmp <= 0;   // SDA low
                    tb_state <= SEND_ADDR;
                end
            end

            SEND_ADDR: begin
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                               // SCL low
                            if (tb_bit_cnt > 0) begin
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1];   // SDA=data (skip 9th bit)
                            end
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                           // slave ACK (drive low)
                                tb_phase <= 2;
                            end else begin
                                tb_phase <= 1;          
                            end
                        end
                        1: begin
                            scl_cmp <= 1;                       // SCL high (data bit)
                            tb_phase <= 0;
                        end
                        2: begin
                            scl_cmp <= 1;                       // SCL high (slave ACK)
                            tb_bit_cnt <= 8;
                            if (tb_in[8]) begin
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
                            scl_cmp <= 0;                               // SCL low
                            if (tb_bit_cnt > 0) begin
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1];   // SDA=data (skip 9th bit)
                            end
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                           // slave ACK (drive low)
                                tb_phase <= 2;
                            end else begin
                                tb_phase <= 1;          
                            end
                        end
                        1: begin
                            scl_cmp <= 1;                      // SCL high (data bit)
                            tb_phase <= 0;
                        end
                        2: begin
                            scl_cmp <= 1;                      // SCL high (slave ACK)
                            out_cmp <= {8'd0,tb_shiftreg};     // update output with response byte
                            tb_state <= IDLE;
                            busy_cmp <= 0;                     // clear busy 
                        end
                    endcase
                end
            end

            READ_BYTE: begin
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                               // SCL low
                            if (tb_bit_cnt > 0) begin
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1];   // SDA=data (skip 9th bit)
                            end
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                           // master ACK (drive low)
                                tb_phase <= 2;
                            end else begin
                                tb_phase <= 1;          
                            end
                        end
                        1: begin
                            scl_cmp <= 1;                      // SCL high (data bit)
                            tb_phase <= 0;
                        end
                        2: begin
                            scl_cmp <= 1;                           // SCL high (master ACK)
                            tb_shiftreg <= tb_mdata[tb_midx];
                            out_cmp <= {8'h80,tb_mdata[tb_midx-1]}; // first byte shifted in, still busy
                            tb_bit_cnt <= 8;
                            tb_state <= READ_BYTE2;
                            tb_phase <= 0;
                        end
                    endcase
                end
            end

            READ_BYTE2: begin
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                               // SCL low
                            if (tb_bit_cnt > 0) begin
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1];   // SDA=data (skip 9th bit)
                            end
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 1;                           // master NACK (drive high)
                                tb_phase <= 2;
                            end else begin
                                tb_phase <= 1;          
                            end
                        end
                        1: begin
                            scl_cmp <= 1;                                 // SCL high (data bit)
                            tb_phase <= 0;
                        end
                        2: begin
                            scl_cmp <= 1;                                 // SCL high for master NACK
                            tb_state <= IDLE;
                            out_cmp <= {tb_mdata[tb_midx-1],tb_shiftreg}; // 2nd byte shifted, done
                            busy_cmp <= 0;                                // clear busy 
                        end
                    endcase
                end
            end
        endcase
    end

    reg fail = 0;
    task check;
        #2
        if ((tb_busy != busy_cmp) || (tb_out !== out_cmp) || (tb_SDA != sda_cmp) || (tb_SCL != scl_cmp)) begin
            // $display("FAIL: tb_clk=%b, tb_load=%b, tb_in=%02h, tb_out=%02h, tb_busy=%b",
            //           tb_clk, tb_load, tb_in, tb_out, tb_busy, tb_SDA, tb_SCL);
            fail = 1;
        end
    endtask

    initial begin
        $dumpfile("RTP_tb.vcd");
        $dumpvars(0, RTP_tb);

        $display("------------------------");
        $display("Testbench: RTP");

        for (tb_n = 0; tb_n < 4000; tb_n = tb_n + 1) begin
            check();
        end

        if (fail == 0) $display("PASSED");
        $display("------------------------");
        $finish;
    end

endmodule