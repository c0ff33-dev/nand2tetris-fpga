// =====================================================
// Simple I2C Master
//   - 25 MHz system clock input
//   - 100 kHz I2C bit rate
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

// 25 MHz / (100 kHz × 4) = 62.5 → ~62 cycles per 1/4 SCL period
// 4 clk cycles per SCL cycle
localparam integer DIVIDER = 25_000_000 / (100_000 * 4);

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

reg sda_oe;         // 1 = drive low, 0 = release
reg scl_oe;         // 1 = drive low, 0 = release

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
    STOP_COND   = 4'd5;

localparam [6:0] DEV_ADDR = 7'h48; // 7-bit I2C device address

reg [3:0] state;
reg [7:0] shift_reg;
reg [3:0] bit_cnt;

always @(posedge clk) begin
    begin
        case (state)
            IDLE: begin
                sda_oe <= 0;
                scl_oe <= 0;
                if (load) begin
                    _out[15] <= 1;  // busy
                    state <= START_COND;
                end
            end

            START_COND: begin
                // SDA goes low while SCL high
                sda_oe <= 1;   // SDA low
                scl_oe <= 0;   // SCL high
                if (tick) begin
                    shift_reg <= {DEV_ADDR, rw};
                    bit_cnt <= 7;
                    state <= SEND_ADDR;
                end
            end

            SEND_ADDR: begin
                if (tick) begin
                    scl_oe <= 1;                    // SCL low
                    sda_oe <= ~shift_reg[bit_cnt];  // set data
                    scl_oe <= 0;                    // SCL high
                    if (bit_cnt == 0) begin
                        if (rw) begin
                            bit_cnt <= 7;
                            state <= READ_BYTE;
                        end else begin
                            bit_cnt <= 7;
                            shift_reg <= in[7:0];   // data to write
                            state <= WRITE_BYTE;
                        end
                    end else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            WRITE_BYTE: begin
                if (tick) begin
                    scl_oe <= 1;
                    sda_oe <= ~shift_reg[bit_cnt];
                    scl_oe <= 0;
                    if (bit_cnt == 0) begin
                        state <= STOP_COND;
                    end else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            READ_BYTE: begin
                sda_oe <= 0; // release SDA
                if (tick) begin
                    _out[bit_cnt] <= sda_in;
                    if (bit_cnt == 0)
                        state <= STOP_COND;
                    else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            STOP_COND: begin
                sda_oe <= 1; // SDA low
                scl_oe <= 0; // SCL high
                if (tick) begin
                    sda_oe <= 0;      // SDA high
                    _out[15] <= 0;     // clear busy
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule
