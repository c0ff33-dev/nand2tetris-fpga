`timescale 10ns/1ns
`default_nettype none

// 100/400 KHz timings: 25 MHz = 1 clk = 40ns = 1/25μs (25 clk/1μs)
// generalized into rough timing buckets

// free time between STOP/START: 4.7μs/1.3μs (~118/~32 clk cycles)
// START/STOP setup/hold: 4.7μs/1.3μs (~118/~118 clk cycles)
// SCL/SDA high/low: 4.7μs/1.3μs (~118/~32 clk cycles)

// data bits after START (high SDA=data)
// - SCL/SDA low to high (same timing)
// - SDA sampled during SCL high
// - SDA shift during SCL low

// TODO: fix/finalize RTP test bench

module RTP_tb();
    reg tb_clk = 0;
    always #2 tb_clk = ~tb_clk; // 25 MHz

    // device under test
    reg tb_load = 0;
    reg [15:0] tb_in = 0; // this is a reg in sim only!
    wire [15:0] tb_out;
    wire SDA, SCL;
    pullup(SDA);
    pullup(SCL);

    RTP rtp (
        .clk(tb_clk),
        .SDA(SDA),
        .SCL(SCL),
        .in(tb_in),
        .out(tb_out),
        .load(tb_load)
    );

    // drive low for data when set, else release (high z)
    reg tb_sda_drv = 0;
    assign SDA = tb_sda_drv ? 1'b0 : 1'bz;

    // master: trigger write command followed by read command
    reg [31:0] tb_n = 0;
    reg tb_write = 1;
    wire trigger = (tb_n == 20) || (tb_n == TB_DIVIDER*180);

    always @(posedge tb_clk) begin
        if (trigger) begin
            tb_load <= 1;
            if (tb_write == 1) begin
                // first trigger write
                tb_in <= {8'd0,tb_mdata[1]}; // command byte
                tb_write <= 0;
            end else begin
                // second trigger read
                tb_in <= 16'h100; // read command (no data)
                tb_write <= 1;
            end
        end else
            tb_load <= 0;
    end

    // testbench state machine
    reg [15:0] out_cmp = 0;
    localparam [3:0]
        IDLE        = 4'd0,
        START_COND  = 4'd1,
        SEND_ADDR   = 4'd2,
        WRITE_BYTE  = 4'd3,   
        READ_BYTE   = 4'd4,
        END_COND    = 4'd5;

    // 400 KHz SCL further divided by 4 (2 tick/tock x 2 sub-phases per high/low)
    localparam integer TB_DIVIDER = 25_000_000 / (400_000 * 2 * 2); 

    reg [9:0] tb_clk_cnt = 0;
    reg tb_tick = 0;
    reg sda_cmp = 1;
    reg scl_cmp = 1;

    reg [3:0] tb_state = IDLE;
    reg [1:0] tb_phase = 0;
    reg [3:0] tb_bit_cnt = 0;
    reg [7:0] tb_shiftreg = 0;

    // input/output data
    reg [7:0] tb_mdata [0:5];  // 5 elements x 8 bits
    reg [2:0] tb_midx = 0;
    reg [3:0] tb_rnd_nibble = 0;

    initial begin
        tb_mdata[0] = 8'h90; // write cmd (no response)
        tb_mdata[1] = $random; // cmd byte
        tb_mdata[2] = 8'h91; // read cmd
        
        // delivers 12 bits serially MSB first and pads the last 4 bits
        tb_rnd_nibble = 4'hA; // $random;
        tb_mdata[3] = 8'hDE; // $random; // read bytes
        tb_mdata[4] = {tb_rnd_nibble,4'd0};
    end

    // generate tick
    always @(posedge tb_clk) begin
        if (out_cmp[15]) begin
            if (tb_clk_cnt == (TB_DIVIDER-1)) begin
                tb_clk_cnt <= 0;
                tb_tick <= 1'b1;
            end else if (tb_clk_cnt == (TB_DIVIDER/2)) begin
                tb_clk_cnt <= tb_clk_cnt + 1;
            end else begin
                tb_clk_cnt <= tb_clk_cnt + 1;
                tb_tick <= 1'b0;
            end
        end else begin
            tb_clk_cnt <= 0;
            tb_tick <= 1'b0;
        end
    end

    // state machine: load/shift low, sample high
    reg tb_next_byte = 0;
    always @(posedge tb_clk) begin
        case (tb_state)
            IDLE: begin // 0
                sda_cmp <= 1; // both high at idle
                scl_cmp <= 1;
                tb_phase <= 0;
                tb_next_byte <= 0;
                if (tb_load) begin
                    // busy from load [t+1]
                    out_cmp <= 16'h8000;

                    // update shift on load
                    tb_shiftreg <= tb_mdata[tb_midx];
                    tb_midx <= tb_midx + 1;
                    tb_bit_cnt <= 8;
                    tb_state <= START_COND;
                end
            end

            START_COND: begin // 1
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            tb_phase <= 1; // continue SCL/SDA high
                        end
                        1: begin
                            tb_phase <= 2; // continue SCL/SDA high
                        end
                        2: begin
                            sda_cmp <= 0;  // SDA low (drive)
                            tb_phase <= 3;
                        end
                        3: begin
                            tb_phase <= 0;
                            tb_state <= SEND_ADDR;
                        end
                    endcase
                end
            end

            SEND_ADDR: begin // 2
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;               // SCL low
                            tb_phase <= 1;
                        end
                        1: begin
                            if (tb_bit_cnt > 0)
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1]; // SDA=data (skip 9th bit)
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;           // slave ACK (drive low)
                                tb_sda_drv <= 1;        // drive SDA low (slave ACK)
                            end
                            tb_phase <= 2;
                        end
                        2: begin
                            scl_cmp <= 1;               // SCL high (data bit/slave ACK)
                            tb_phase <= 3;
                        end
                        3: begin
                            if (tb_bit_cnt > 8) begin   // SCL high (continues) - data bit/slave ACK
                                if (tb_in[8])
                                    tb_state <= READ_BYTE;
                                else 
                                    tb_state <= WRITE_BYTE;
                                tb_bit_cnt <= 8;
                                tb_shiftreg <= tb_mdata[tb_midx];
                                tb_midx <= tb_midx + 1;
                            end
                            tb_phase <= 0;
                        end
                    endcase
                end
            end

            WRITE_BYTE: begin // 3
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                      // SCL low
                            tb_phase <= 1;                       
                        end
                        1: begin
                            if (tb_bit_cnt > 0)
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1]; // SDA=data (skip 9th bit)
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                  // slave ACK (drive low)
                                tb_sda_drv <= 1;               // drive SDA low (slave ACK)
                            end else
                                tb_sda_drv <= 0;
                            tb_phase <= 2;
                        end
                        2: begin
                            scl_cmp <= 1;                      // SCL high (data bit/slave ACK)
                            tb_phase <= 3;
                        end
                        3: begin
                            if (tb_bit_cnt > 8) begin
                                tb_state <= END_COND;
                                tb_shiftreg <= 0;
                            end
                            tb_phase <= 0;
                        end
                    endcase
                end
            end

            READ_BYTE: begin // 4
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0; // SCL low
                            tb_phase <= 1;
                        end
                        1: begin
                            if (tb_bit_cnt > 0) begin
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1]; // SDA=data
                                tb_sda_drv <= ~tb_shiftreg[tb_bit_cnt-1];
                            end else begin
                                tb_sda_drv <= 0;  // release SDA for master [N]ACK
                                sda_cmp <= tb_next_byte; // master [N]ACK
                            end
                            tb_phase <= 2;
                        end
                        2: begin
                            scl_cmp <= 1; // SCL high (release) - data bit/master [N]ACK
                            tb_phase <= 3;
                        end
                        3: begin
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt==0) begin
                                sda_cmp <= tb_next_byte; // master [N]ACK
                                if (~tb_next_byte) begin
                                    tb_shiftreg <= tb_mdata[tb_midx];
                                    out_cmp <= {8'h80,tb_mdata[tb_midx-1]}; // first byte shifted in, still busy
                                    tb_next_byte <= 1;
                                    tb_bit_cnt <= 8; // start next count
                                    tb_sda_drv <= 0; // clear ACK
                                end else begin
                                    out_cmp <= {
                                        4'h8,
                                        tb_mdata[tb_midx-1],
                                        tb_shiftreg[7:4]
                                    }; // second byte shifted in, still busy
                                    tb_state <= END_COND;
                                end
                            end
                            tb_phase <= 0;
                        end
                    endcase
                end
            end

            END_COND: begin // 5
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0; // SCL low (drive)
                            tb_phase <= 1;
                        end
                        1: begin
                            sda_cmp <= 0; // SDA low (drive)
                            tb_phase <= 2;
                            tb_sda_drv <= 0; // clear ACK
                        end
                        2: begin
                            scl_cmp <= 1; // SCL high (release) - final
                            tb_phase <= 3;
                        end
                        3: begin
                            sda_cmp <= 1; // SDA high (release) - final
                            tb_phase <= 0;
                            out_cmp[15] <= 0; // clear busy bit
                            tb_state <= IDLE;
                        end
                    endcase
                end
            end
        endcase
    end

    reg fail = 0;
    task check;
        #2
        if ((tb_out !== out_cmp) || (SDA != sda_cmp) || (SCL != scl_cmp)) begin
            fail = 1;
        end
    endtask

    initial begin
        $dumpfile("RTP_tb.vcd");
        $dumpvars(0, RTP_tb);

        $display("------------------------");
        $display("Testbench: RTP");

        for (tb_n = 0; tb_n < 60000; tb_n = tb_n + 1) begin
            check();
        end

        if (fail == 0) $display("PASSED");
        $display("------------------------");
        $finish;
    end

endmodule