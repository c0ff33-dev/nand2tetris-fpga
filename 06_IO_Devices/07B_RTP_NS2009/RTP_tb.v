`timescale 10ns/1ns
`default_nettype none

// 100/400 KHz timings: 25MHz = 1 clk = 40ns = 1/25μs (25 clk/μs)
// note: these are NOT evenly divided in standard vs fast mode!
// generalized into rough timing buckets

// free time between STOP/START: 4.7μs/1.3μs (~118/~32 clk cycles)
// START/STOP setup/hold: 4.7μs/1.3μs (~118/~118 clk cycles)
// SCL/SDA high/low: 4.7μs/1.3μs (~118/~32 clk cycles)
// in fast mode SCL is 1/3 high, 2/3 low but NS2009 is plenty fast

// data bits after START (high SDA=data)
// - SCL/SDA low to high (same timing)
// - SDA sampled during SCL high
// - SDA shift during SCL low

// FIXME: tried swapping SDA/SCL wires but it went to 0xFF (as expected if not driven so its reacting to SCL)
// FIXME: actively driving SCL also results in 0xFF
// FIXME: basically any sampling of SDA outside of the SEND_ADDR ACK window(s) seems broken, no change using SCL midpoint
// FIXME: 0x5A/0x55 style output is still too uniform though to be chance
// FIXME: no change in output at < 100 KHz speeds
// FIXME: no change in output with change in target register (but 0xFF if wrong device addr so thats something)

// TODO: START/STOP_COND is one tick each for setup/hold so this is technically clipping (but unlikely to break)
// TODO: padding the end with ~2 SCL ticks (setup/hold) is better than using a software timer for free bus time (if room)

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

    reg tb_sda_drv = 0;   // drive low for data when set, else release (high z)
    assign SDA = tb_sda_drv ? 1'b0 : 1'bz;

    reg [7:0] tb_slv_data = 0;
    reg [3:0] tb_slv_bitcnt = 0;
    reg tb_slv_sending = 0;

    wire tb_busy = tb_out[15];
    
    // slave: drive SDA to return data to master
    always @(negedge SCL) begin
        if (tb_state==SEND_ADDR || tb_state==WRITE_BYTE) begin
            tb_slv_bitcnt <= tb_slv_bitcnt + 1;
            if (tb_slv_bitcnt == 8) begin
                tb_sda_drv <= 1; // drive SDA low (slave ACK)
                tb_slv_bitcnt <= 0; 
            end else
                tb_sda_drv <= 0; // release SDA
            if (tb_state==WRITE_BYTE)
                tb_slv_data <= tb_mdata[3]; // set write byte
        end
        else if (tb_state==READ_BYTE || tb_state==READ_BYTE2) begin
            if (tb_slv_bitcnt == 8) begin
                tb_slv_bitcnt <= 0;
                tb_slv_sending <= 0;
                tb_slv_data <= tb_mdata[4]; // set next read byte
                tb_sda_drv <= 0; // release SDA for master ACK
            end else begin
                tb_sda_drv <= ~tb_slv_data[7 - tb_slv_bitcnt];
                tb_slv_sending <= 1;
                tb_slv_bitcnt <= tb_slv_bitcnt + 1;
            end
        end else
            tb_sda_drv <= 0; // release SDA
    end

    // on the real chip ACK would drive SDA low for a full cycle
    // but in tb there are no more ticks and we don't sample the ACK
    always @(posedge SCL) begin
        if (tb_state==IDLE) begin
            tb_sda_drv <= 0; // release SDA
        end
    end

    // master: trigger write command followed by read command
    reg [31:0] tb_n = 0;
    reg tb_write = 1;
    wire trigger = (tb_n == 20) || (tb_n == TB_DIVIDER*90);

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
    reg busy_cmp = 0;

    localparam [3:0]
        IDLE        = 4'd0,
        START_COND  = 4'd1,
        SEND_ADDR   = 4'd2,
        WRITE_BYTE  = 4'd3,   
        READ_BYTE   = 4'd4,
        READ_BYTE2  = 4'd5;

    localparam TB_DIVIDER = 125; // 125/~31 clk cycles @ 25 MHz = 100/400 KHz SCL
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
        tb_rnd_nibble = $random;
        tb_mdata[3] = $random; // read bytes
        tb_mdata[4] = {tb_rnd_nibble,4'd0};
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

    // state machine: load/shift low, sample high
    reg tb_loaded = 0;
    always @(posedge tb_clk) begin
        case (tb_state)
            IDLE: begin // 0
                sda_cmp <= 1; // both high at idle
                scl_cmp <= 1;
                tb_phase <= 0;
                if (tb_load) begin
                    // busy from load [t+1]
                    busy_cmp <= 1; 
                    out_cmp <= 16'h8000;

                    // update shift on load
                    tb_shiftreg <= tb_mdata[tb_midx];
                    tb_midx <= tb_midx + 1;
                    tb_bit_cnt <= 8;

                    // tb_loaded <= 1;
                    tb_state <= START_COND;
                end

                // if (tb_loaded) begin
                //     // tb_state <= START_COND;
                //     tb_loaded <= 0;
                // end
            end

            START_COND: begin // 1
                if (tb_tick) begin
                    scl_cmp <= 1;   // SCL high
                    sda_cmp <= 0;   // SDA low
                    tb_state <= SEND_ADDR;
                end
            end

            SEND_ADDR: begin // 2
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                               // SCL low
                            if (tb_bit_cnt > 0)
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1];   // SDA=data (skip 9th bit)
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                           // slave ACK (drive low)
                                tb_phase <= 2;
                            end else
                                tb_phase <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;               // SCL high (data bit)
                            tb_phase <= 0;
                        end
                        2: begin
                            scl_cmp <= 1;               // SCL high (slave ACK)
                            tb_bit_cnt <= 8;
                            if (tb_in[8])
                                tb_state <= READ_BYTE;
                            else 
                                tb_state <= WRITE_BYTE;
                            tb_phase <= 0;
                            tb_shiftreg <= tb_mdata[tb_midx];
                            tb_midx <= tb_midx + 1;
                        end
                    endcase
                end
            end

            WRITE_BYTE: begin // 3
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                               // SCL low
                            if (tb_bit_cnt > 0)
                                sda_cmp <= tb_shiftreg[tb_bit_cnt-1];   // SDA=data (skip 9th bit)
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                           // slave ACK (drive low)
                                tb_phase <= 2;
                            end else
                                tb_phase <= 1;
                        end
                        1: begin
                            scl_cmp <= 1;                      // SCL high (data bit)
                            tb_phase <= 0;
                        end
                        2: begin
                            scl_cmp <= 1;                      // SCL high (slave ACK)
                            sda_cmp <= 1;                      // release SDA
                            out_cmp <= 0;                      // update output with response byte
                            tb_state <= IDLE;
                            busy_cmp <= 0;                     // clear busy 
                            tb_shiftreg <= 0;
                        end
                    endcase
                end
            end

            READ_BYTE: begin // 4
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                           // SCL low
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 0;                       // master ACK (drive low)
                                tb_phase <= 2;
                            end else begin
                                tb_phase <= 1;
                                if (tb_bit_cnt > 0)
                                    sda_cmp <= tb_shiftreg[tb_bit_cnt-1]; // SDA=data (skip 9th bit)
                            end
                        end
                        1: begin
                            scl_cmp <= 1;                           // SCL high (data bit)
                            tb_bit_cnt <= tb_bit_cnt - 1;
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

            READ_BYTE2: begin // 5
                if (tb_tick) begin
                    case (tb_phase)
                        0: begin
                            scl_cmp <= 0;                                 // SCL low
                            if (tb_bit_cnt == 0) begin
                                sda_cmp <= 1;                             // master NACK (SDA high)
                                tb_phase <= 2;
                            end else
                                tb_phase <= 1;
                                if (tb_bit_cnt > 0)
                                    sda_cmp <= tb_shiftreg[tb_bit_cnt-1]; // SDA=data (skip 9th bit)
                        end
                        1: begin
                            scl_cmp <= 1;                                 // SCL high (data bit)
                            tb_bit_cnt <= tb_bit_cnt - 1;
                            tb_phase <= 0;
                        end
                        2: begin
                            scl_cmp <= 1;                                 // SCL high for master NACK
                            tb_state <= IDLE;
                            out_cmp <= {
                                4'd0,
                                tb_mdata[tb_midx-1],
                                tb_shiftreg[7:4]
                            };
                            busy_cmp <= 0;                                // clear busy
                            tb_shiftreg <= 0;
                        end
                    endcase
                end
            end
        endcase
    end

    reg fail = 0;
    task check;
        #2
        if ((tb_busy != busy_cmp) || (tb_out !== out_cmp) || (SDA != sda_cmp) || (SCL != scl_cmp)) begin
            $display("FAIL: tb_clk=%b, tb_load=%b, tb_in=%02h, tb_out=%02h, tb_busy=%b",
                      tb_clk, tb_load, tb_in, tb_out, tb_busy, SDA, SCL);
            fail = 1;
        end
    endtask

    initial begin
        $dumpfile("RTP_tb.vcd");
        $dumpvars(0, RTP_tb);

        $display("------------------------");
        $display("Testbench: RTP");

        for (tb_n = 0; tb_n < 30000; tb_n = tb_n + 1) begin
            check();
        end

        if (fail == 0) $display("PASSED");
        $display("------------------------");
        $finish;
    end

endmodule