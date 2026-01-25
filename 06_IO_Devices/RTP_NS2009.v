// NS2009 Resistive Touch Panel (RTP) controller
// 400 KHz I2C interface
// 7 bit device address: 0x48 (0x90 write, 0x91 read)
// no response other than the ACK bit for writes
// 12 bit response for reads (two bytes, MSB first, last 4 bits zero)

module RTP (
    input  wire        clk,
    input  wire        load,
    input  wire [15:0] in,    // in[8]=r/w (0=write/1=read), in[7:0]=command (if write)
    inout  wire        SDA,   // I2C data line (inout to allow open drain)
    inout  wire        SCL,    // I2C clock (inout to allow open drain)
    output wire [15:0] out   // out[15]=busy, [7:0]=data (if read)
);

// 400 KHz SCL further divided by 4 (2 tick/tock x 2 sub-phases per high/low)
localparam integer DIVIDER = 25_000_000 / (400_000 * 2 * 2); 

reg [9:0] clk_cnt;
reg tick; // SCL clock: tick/tock every DIVIDER clk cycles
reg [7:0] hi_byte = 0;
reg [7:0] lo_byte = 0;
reg [15:0] next_out = 0;

assign out = next_out;

// clock divider for I2C SCL timing
always @(posedge clk) begin
    if (out[15]) begin // busy
        if (clk_cnt == (DIVIDER-1)) begin
            clk_cnt <= 0;
            tick <= 1'b1;
        end else if (clk_cnt == (DIVIDER/2)) begin
            clk_cnt <= clk_cnt + 1;
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

localparam [2:0]
    IDLE        = 4'd0,
    START_COND  = 4'd1,
    SEND_ADDR   = 4'd2,
    WRITE_BYTE  = 4'd3,   
    READ_BYTE   = 4'd4,
    END_COND    = 4'd5;

localparam [6:0] DEV_ADDR = 7'h48; // 7 bit device address for NS2009

reg [2:0] state = IDLE;
reg [7:0] addr = 0, data = 0;
reg [3:0] bit_cnt = 0;
reg [1:0] phase = 0; // steps in each state (varies)
reg rw = 0;

// state machine: load/shift low, sample high, release for slave ACK/response
// need 9 SCL cycles per byte (8 data + ACK/NACK)
// bit processing is pretty much the same except for ACK/NACK and output/sampling
reg loaded = 0;
reg next_byte = 0;
always @(posedge clk) begin
    case (state)
        IDLE: begin // 0
            scl_oe <= 0; // SCL high (release)
            sda_oe <= 0; // SDA high (release)
            phase <= 0;
            next_byte <= 0;
            if (load) begin
                rw <= in[8];   // read/write bit
                next_out[15] <= 1;  // busy
                addr <= {DEV_ADDR, in[8]}; // 7 bit address + r/w bit
                if (in[8] == 0)
                    data <= in[7:0]; // command byte for write
                else
                    data <= 0;       // unused for read
                bit_cnt <= 8;
                loaded <= 1;
            end
            
            // wait for lines to rise (don't block on SDA)
            // if unconditional transition this will never be reached when loaded=1
            if (loaded) begin
                loaded <= 0;
                state <= START_COND;
            end
        end

        // set START bit for one SCL high period 
        // SDA drops while SCL is high to trigger START
        START_COND: begin // 1
            if (tick) begin
                case (phase)
                    0: begin
                        phase <= 1; // continue SCL/SDA high
                    end
                    1: begin
                        phase <= 2; // continue SCL/SDA high
                    end
                    2: begin
                        sda_oe <= 1; // SDA low (drive)
                        phase <= 3;
                    end
                    3: begin
                        phase <= 0;
                        state <= SEND_ADDR;
                    end
                endcase
            end
        end

        SEND_ADDR: begin // 2
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                     // SCL low (drive)
                        phase <= 1;
                    end
                    1: begin
                        if (bit_cnt > 0)
                            sda_oe <= ~addr[bit_cnt-1];  // SDA=data (skip 9th bit)
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 0)
                            sda_oe <= 0;                 // release SDA for slave ACK
                        phase <= 2;
                    end
                    2: begin
                        scl_oe <= 0;                     // SCL high (release) - data bit
                        phase <= 3;
                    end
                    3: begin
                        if (bit_cnt > 8) begin           // SCL high (continues) - data bit/slave ACK
                            if (rw)
                                state <= READ_BYTE;
                            else
                                state <= WRITE_BYTE;
                            bit_cnt <= 8;
                        end
                        phase <= 0;
                    end
                endcase
            end
        end

        WRITE_BYTE: begin // 3
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                    // SCL low (drive)
                        phase <= 1;
                    end
                    1: begin
                        if (bit_cnt > 0)
                            sda_oe <= ~data[bit_cnt-1]; // SDA=data (skip 9th bit)
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt == 0)
                            sda_oe <= 0;                // release SDA for slave ACK
                        phase <= 2;
                    end
                    2: begin
                        scl_oe <= 0;                    // SCL high (release) - data bit/slave ACK
                        phase <= 3;
                    end
                    3: begin                            // continue SCL/SDA
                        if (bit_cnt > 8) begin
                            state <= END_COND;
                            rw <= 0;
                        end
                        phase <= 0;
                    end
                endcase
            end
        end

        READ_BYTE: begin // 4
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                    // SCL low (drive)
                        phase <= 1;
                    end
                    1: begin
                        if (bit_cnt==0)
                            sda_oe <= ~next_byte;       // drive/release SDA: master [N]ACK
                        else 
                            sda_oe <= 0;                // release SDA (incoming data)
                        phase <= 2;
                    end
                    2: begin
                        scl_oe <= 0;                    // SCL high (release) - data bit/master [N]ACK
                        phase <= 3;
                    end
                    3: begin
                        bit_cnt <= bit_cnt - 1;
                        if (bit_cnt > 0) begin
                            // adjust offset for reduced count in 2nd byte
                            if (~next_byte)
                                hi_byte[bit_cnt-1] <= SDA;
                            else
                                lo_byte[bit_cnt-1] <= SDA;
                        end
                        if (bit_cnt==0) begin
                            if (~next_byte) begin
                                next_out <= {8'h80,hi_byte}; // first byte shifted in, still busy
                                next_byte <= 1;
                                bit_cnt <= 8;                // start next count
                            end else begin
                                next_out <= {                // second byte shifted in, still busy
                                    4'h8,
                                    hi_byte,
                                    lo_byte[7:4]
                                };
                                state <= END_COND;
                                rw <= 0;
                            end
                        end
                        phase <= 0;
                    end
                endcase
            end
        end

        // set STOP bit for one SCL high period 
        // drive SDA low during SCL low (setup) 
        // then release SDA high while SCL high to trigger STOP
        END_COND: begin // 5
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1; // SCL low (drive)
                        phase <= 1;
                    end
                    1: begin
                        sda_oe <= 1; // SDA low (drive)
                        phase <= 2;
                    end
                    2: begin
                        scl_oe <= 0; // SCL high (release) - final
                        phase <= 3;
                    end
                    3: begin
                        sda_oe <= 0; // SDA high (release) - final
                        phase <= 0;
                        next_out[15] <= 0;
                        state <= IDLE;
                    end
                endcase
            end
        end
    endcase
end

endmodule