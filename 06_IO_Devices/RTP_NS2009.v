// NS2009 Resistive Touch Panel (RTP) controller
// 400 KHz I2C interface
// 7 bit device address: 0x48 (0x90 write, 0x91 read)
// no response other than the ACK bit for writes
// 12 bit response for reads (two bytes, MSB first)

module RTP (
    input  wire        clk,
    input  wire        load,
    input  wire [15:0] in,    // in[8]=r/w (0=write/1=read), in[7:0]=command (if write)
    inout  wire        SDA,   // I2C data line (inout to allow open-drain)
    inout  wire        SCL,   // I2C clock (inout to allow open-drain)
    output wire [15:0] out,   // out[15]=busy, [7:0]=data (if read)
    output reg led_load = 0,
    output reg [15:0] led_out = 0
);

// 25 MHz / 100 KHz = ~31 clk cycles per SCL
localparam integer DIVIDER = 25_000_000 / (100_000 * 2); // x2 for tick/tock

reg [9:0] clk_cnt;
reg tick; // SCL clock: tick/tock every DIVIDER clk cycles
reg [7:0] hi_byte = 0;
reg [7:0] lo_byte = 0;
reg [15:0] next_out = 0;

assign out = next_out;

// clock divider for I2C SCL timing
always @(posedge clk) begin
    if (out[15]) begin // busy
        if (clk_cnt == DIVIDER - 1) begin
            clk_cnt <= 0;
            tick <= 1'b1;
        end else begin
            clk_cnt <= clk_cnt + 1;
            tick <= 1'b0;
        end
    end else begin
        clk_cnt <= 0;
        tick <= 1'b0;
    end
end

// 1 = drive low, 0 = release (pulled high if not driven)
reg sda_oe = 0;         
reg scl_oe = 0;
assign SDA = sda_oe ? 1'b0 : 1'bz;
assign SCL = scl_oe ? 1'b0 : 1'bz;

localparam [3:0]
    IDLE        = 4'd0,
    START_COND  = 4'd1,
    SEND_ADDR   = 4'd2,
    WRITE_BYTE  = 4'd3,   
    READ_BYTE   = 4'd4,
    READ_BYTE2  = 4'd5;

localparam [6:0] DEV_ADDR = 7'h48; // 7-bit device address for NS2009

reg [3:0] state = IDLE;
reg [7:0] addr = 0, data = 0;
reg [3:0] bit_cnt = 0;
reg [1:0] phase = 0; // steps in each state (varies)
reg rw = 0;

// debug FSM
// - can't sample directly at edge, some noise during SCL low
// - clean ACK recv'd during SEND_ADDR/phase 3
// - clean ACK recv'd during WRITE_BYTE/phase 3
always @(posedge clk) begin
    // poll throughout the entire SCL period
    // if (state==SEND_ADDR && phase==3) begin
    if (state==WRITE_BYTE && phase==3) begin
        // check for ACK
        if (~SDA && SCL && led_out==0) begin
            led_load <= 1;
            led_out <= 1;
        end
        // check for SDA flapping
        if (SDA && SCL && led_out>=1) begin
            led_load <= 1;
            led_out <= 3;
        end
    end
end

// state machine: load/shift low, sample high, release for slave ACK/response
// need 9 SCL cycles per byte (8 data + ACK/NACK)
// bit processing is pretty much the same except for ACK/NACK and output/sampling
always @(posedge clk) begin
    case (state)
        IDLE: begin // 0
            scl_oe <= 0; // SCL high (release)
            sda_oe <= 0; // SDA high (release)
            phase <= 0;
            if (load) begin
                rw <= in[8];   // read/write bit
                next_out[15] <= 1;  // busy
                addr <= {DEV_ADDR, in[8]}; // 7 bit address + r/w bit
                if (in[8] == 0)
                    data <= in[7:0]; // command byte for write
                else
                    data <= 0;       // unused for read
                state <= START_COND;
                bit_cnt <= 8;
            end
        end

        START_COND: begin // 1
            if (tick) begin
                scl_oe <= 0;   // SCL high (release)
                sda_oe <= 1;   // SDA low (drive)
                state <= SEND_ADDR;
            end
        end

        SEND_ADDR: begin // 2
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                       // SCL low (drive)
                        if (bit_cnt > 0)
                            sda_oe <= ~addr[bit_cnt-1];    // SDA=data (skip 9th bit)
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 0) begin
                            sda_oe <= 0;                   // release SDA for slave ACK
                            phase <= 2;
                        end else
                            phase <= 1;
                    end
                    1: begin
                        scl_oe <= 0;                       // SCL high (release) - data bit
                        phase <= 0;
                    end
                    2: begin
                        scl_oe <= 0;                       // SCL high (release) - slave ACK
                        bit_cnt <= 8;
                        if (rw)
                            state <= READ_BYTE;
                        else
                            state <= WRITE_BYTE;
                        phase <= 0;
                    end
                endcase
            end
        end

        WRITE_BYTE: begin // 3
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                       // SCL low (drive)
                        if (bit_cnt > 0)
                            sda_oe <= ~data[bit_cnt-1];    // SDA=data (skip 9th bit)
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 0) begin
                            sda_oe <= 0;                   // release SDA for slave ACK
                            phase <= 2;
                        end else
                            phase <= 1;
                    end
                    1: begin
                        scl_oe <= 0;                       // SCL high (release) - data bit
                        phase <= 0;
                    end
                    2: begin
                        scl_oe <= 0;                       // SCL high (release) - slave ACK
                        state <= IDLE;
                        next_out <= 0;                          // clear busy
                        rw <= 0;
                    end
                endcase
            end
        end

        // FIXME: SDA reads possibly too close to SCL transition?
        READ_BYTE: begin // 4
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                    // SCL low (drive)
                        if (bit_cnt == 0) begin
                            sda_oe <= 1;                // master ACK (drive low)
                            phase <= 2;
                        end else begin
                            sda_oe <= 0;                // release SDA (incoming data)
                            phase <= 1;
                        end
                    end
                    1: begin
                        scl_oe <= 0;                    // SCL high (release) - data bit
                        if (bit_cnt > 0)
                            hi_byte[bit_cnt-1] <= SDA;  // sample SDA
                        bit_cnt <= bit_cnt - 1;
                        phase <= 0;
                    end
                    2: begin
                        scl_oe <= 0;                    // SCL high (release) - master ACK
                        next_out <= {8'h80,hi_byte};         // first byte shifted in, still busy
                        bit_cnt <= 8;                   // prepare for second byte
                        state <= READ_BYTE2;
                        phase <= 0;
                    end
                endcase
            end
        end

        READ_BYTE2: begin // 5
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                    // SCL low (drive)
                        if (bit_cnt == 0) begin
                            sda_oe <= 0;                // SDA high (release) - master NACK
                            phase <= 2;
                        end else begin
                            sda_oe <= 0;                // release SDA (incoming data)
                            phase <= 1;
                        end
                    end
                    1: begin
                        scl_oe <= 0;                    // SCL high (release) - data bit
                        if (bit_cnt > 0)
                            lo_byte[bit_cnt-1] <= SDA;  // sample SDA (write to lower byte out)
                        bit_cnt <= bit_cnt - 1;
                        phase <= 0;
                    end
                    2: begin
                        scl_oe <= 0;                    // SCL high (release) - master ACK
                        next_out <= {                   // shuffle the bytes back into a 16 bit integer
                            4'd0,                       // shift the padded bits to the top
                            hi_byte,                    // high byte as received   
                            lo_byte[7:4]                // low byte upper nibble
                        };
                        state <= IDLE;
                        rw <= 0;
                    end
                endcase
            end
        end
    endcase
end

endmodule