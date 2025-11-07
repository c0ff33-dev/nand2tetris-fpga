// =====================================================
// Simple I2C Master
//   - 25 MHz system clock input
//   - 100 KHz I2C bit rate
//   - Handles single-byte read or write
// =====================================================

module RTP (
    input  wire        clk,
    input  wire        load,
    input  wire [15:0] in,    // in[8]=r/w (0=write/1=read), in[7:0]=data (if write)
    inout  wire        SDA,
    inout  wire        SCL,
    output wire [15:0] out    // out[15]=busy, [7:0]=data (if read)
);

// 25 MHz / (100 KHz × 4) = 62.5 → ~62 cycles per 1/4 SCL period
// 4 clk cycles per SCL cycle
localparam integer DIVIDER = 25_000_000 / (400_000 * 4);

reg [9:0] clk_cnt;
reg tick;
reg [15:0] _out = 0;

assign out = _out;
wire busy = out[15];
wire rw = in[8];

always @(posedge clk) begin
    if (busy) begin
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

// TODO: is there actually a pull-up resistor on SDA?
// 1 = drive low, 0 = release
reg sda_oe;         
reg scl_oe;
assign SDA = sda_oe ? 1'b0 : 1'bz;
assign SCL = scl_oe ? 1'b0 : 1'bz;

wire sda_in = SDA;
wire scl_in = SCL;

localparam [3:0]
    IDLE        = 4'd0,
    START_COND  = 4'd1,
    SEND_ADDR   = 4'd2,
    WRITE_BYTE  = 4'd3,   
    READ_BYTE   = 4'd4,
    READ_BYTE2  = 4'd5,
    STOP_COND   = 4'd6;

localparam [6:0] DEV_ADDR = 7'h48; // 7-bit I2C device address

reg [3:0] state = IDLE;
reg [7:0] shift_reg;
reg [3:0] bit_cnt;
reg [1:0] phase;  // 0=data_setup, 1=scl_high, 2=scl_low, 3=next_bit

// TODO: update state machine to read two bytes during ready cycle (in[8]=1)
always @(posedge clk) begin
    case (state)
        IDLE: begin
            sda_oe <= 0;
            scl_oe <= 0;
            phase <= 0;
            if (load) begin
                _out[15] <= 1;  // busy
                shift_reg <= {DEV_ADDR, in[8]};
                state <= START_COND;
            end
        end

        START_COND: begin
            if (tick) begin
                case (phase)
                    0: begin
                        // START: SDA goes low while SCL high
                        sda_oe <= 1;   // SDA low
                        scl_oe <= 0;   // SCL high
                        phase <= 1;
                    end
                    1: begin
                        bit_cnt <= 7;
                        phase <= 0;
                        state <= SEND_ADDR;
                    end
                    default: phase <= 0;
                endcase
            end
        end

        SEND_ADDR: begin
            if (tick) begin
                case (phase)
                    0: begin
                        // Data setup with SCL low
                        scl_oe <= 1;                    // SCL low
                        sda_oe <= ~shift_reg[bit_cnt];  // set data
                        phase <= 1;
                    end
                    1: begin
                        // SCL high - data valid
                        scl_oe <= 0;                    // SCL high
                        phase <= 2;
                    end
                    2: begin
                        // Prepare for next bit
                        scl_oe <= 1;                    // SCL low
                        if (bit_cnt == 0) begin
                            // ACK bit - release SDA
                            sda_oe <= 0;
                            phase <= 3;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                            phase <= 0;
                        end
                    end
                    3: begin
                        // ACK phase - SCL high to sample ACK
                        scl_oe <= 0;                    // SCL high
                        // Transition to next state
                        if (rw) begin
                            bit_cnt <= 7;
                            state <= READ_BYTE;
                        end else begin
                            bit_cnt <= 7;
                            shift_reg <= in[7:0];   // data to write
                            state <= WRITE_BYTE;
                        end
                        phase <= 0;
                    end
                endcase
            end
        end

        WRITE_BYTE: begin
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                    // SCL low
                        sda_oe <= ~shift_reg[bit_cnt];  // set data
                        phase <= 1;
                    end
                    1: begin
                        scl_oe <= 0;                    // SCL high
                        phase <= 2;
                    end
                    2: begin
                        scl_oe <= 1;                    // SCL low
                        if (bit_cnt == 0) begin
                            // ACK bit
                            sda_oe <= 0;
                            phase <= 3;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                            phase <= 0;
                        end
                    end
                    3: begin
                        scl_oe <= 0;                    // SCL high for ACK
                        state <= STOP_COND;
                        phase <= 0;
                    end
                endcase
            end
        end

        READ_BYTE: begin
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                    // SCL low
                        sda_oe <= 0;                    // release SDA
                        phase <= 1;
                    end
                    1: begin
                        scl_oe <= 0;                    // SCL high
                        _out[bit_cnt] <= sda_in;        // sample data
                        phase <= 2;
                    end
                    2: begin
                        scl_oe <= 1;                    // SCL low
                        if (bit_cnt == 0) begin
                            sda_oe <= 0;                // ACK bit - drive low
                            phase <= 3;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                            phase <= 0;
                        end
                    end
                    3: begin
                        scl_oe <= 0;                    // SCL high for NACK
                        state <= READ_BYTE2;
                        phase <= 0;
                    end
                endcase
            end
        end

        READ_BYTE2: begin
            if (tick) begin
                case (phase)
                    0: begin
                        scl_oe <= 1;                    // SCL low
                        sda_oe <= 0;                    // release SDA
                        phase <= 1;
                    end
                    1: begin
                        scl_oe <= 0;                    // SCL high
                        _out[bit_cnt] <= sda_in;        // sample data
                        phase <= 2;
                    end
                    2: begin
                        scl_oe <= 1;                    // SCL low
                        if (bit_cnt == 0) begin
                            sda_oe <= 1;                // NACK bit - drive high
                            phase <= 3;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                            phase <= 0;
                        end
                    end
                    3: begin
                        scl_oe <= 0;                    // SCL high for NACK
                        state <= STOP_COND;
                        phase <= 0;
                    end
                endcase
            end
        end

        STOP_COND: begin
            if (tick) begin
                case (phase)
                    0: begin
                        // STOP: SDA rises while SCL high
                        sda_oe <= 1;                    // SDA low
                        scl_oe <= 0;                    // SCL high
                        phase <= 1;
                    end
                    1: begin
                        sda_oe <= 0;                    // SDA high (release)
                        _out[15] <= 0;                  // clear busy
                        state <= IDLE;
                        phase <= 0;
                    end
                    default: phase <= 0;
                endcase
            end
        end
    endcase
end

endmodule