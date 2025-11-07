// =====================================================
// Simple I2C Master
//   - 25 MHz system clock input
//   - 100 kHz I2C bit rate
//   - Handles single-byte read or write
// =====================================================

module RTP (
    input  wire        clk,        // 25 MHz system clock
    input  wire        reset_n,    // Active-low async reset

    // I2C bus
    inout  wire        sda,
    inout  wire        scl,

    // Control interface
    input  wire [7:0]  in,         // Data to write
    output reg  [7:0]  rd_data,    // Data read
    input  wire        load,       // Begin transaction
    input  wire        rw,         // 0 = write, 1 = read
    output reg         busy        // 1 = transaction in progress
);

// -------------------------------------------------
// Clock divider (for I2C timing ticks)
// -------------------------------------------------
// 25 MHz / (100 kHz × 4) = 62.5 → ~62 cycles per 1/4 SCL period
// 4 ticks per SCL cycle
localparam integer DIVIDER = 25_000_000 / (100_000 * 4);

reg [9:0] clk_cnt;
reg tick;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        clk_cnt <= 0;
        tick <= 0;
    end else if (busy) begin
        if (clk_cnt == DIVIDER - 1) begin
            clk_cnt <= 0;
            tick <= 1'b1;   // One-cycle pulse
        end else begin
            clk_cnt <= clk_cnt + 1;
            tick <= 1'b0;
        end
    end else begin
        clk_cnt <= 0;
        tick <= 1'b0;
    end
end

// -------------------------------------------------
// Open-drain SDA and SCL
// -------------------------------------------------
reg sda_oe;         // 1 = drive low, 0 = release
reg scl_oe;         // 1 = drive low, 0 = release

assign sda = sda_oe ? 1'b0 : 1'bz;
assign scl = scl_oe ? 1'b0 : 1'bz;

wire sda_in = sda;
wire scl_in = scl;

// -------------------------------------------------
// I2C Master FSM
// -------------------------------------------------
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

// -------------------------------------------------
// Main FSM
// -------------------------------------------------
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        busy      <= 0;
        sda_oe    <= 0;
        scl_oe    <= 0;
        bit_cnt   <= 0;
        rd_data   <= 8'h00;
        state     <= IDLE;
    end else begin
        case (state)
            // -------------------------------------------------
            IDLE: begin
                sda_oe <= 0;
                scl_oe <= 0;
                if (load) begin
                    busy <= 1;
                    state <= START_COND;
                end
            end

            // -------------------------------------------------
            START_COND: begin
                // SDA goes low while SCL high
                sda_oe <= 1;   // SCL low
                scl_oe <= 0;   // SDA high
                if (tick) begin
                    shift_reg <= {DEV_ADDR, rw};
                    bit_cnt <= 7;
                    state <= SEND_ADDR;
                end
            end

            // -------------------------------------------------
            SEND_ADDR: begin
                if (tick) begin
                    scl_oe <= 1;                    // SCL low
                    sda_oe <= ~shift_reg[bit_cnt];  // set data
                    scl_oe <= 0;                    // SCL high (ignore slave clock)
                    if (bit_cnt == 0) begin
                        if (rw) begin
                            bit_cnt <= 7;
                            state <= READ_BYTE;
                        end else begin
                            bit_cnt <= 7;
                            shift_reg <= in;
                            state <= WRITE_BYTE;
                        end
                    end else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            // -------------------------------------------------
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

            // -------------------------------------------------
            READ_BYTE: begin
                sda_oe <= 0; // release SDA
                if (tick) begin
                    rd_data[bit_cnt] <= sda_in;
                    if (bit_cnt == 0)
                        state <= STOP_COND;
                    else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            // -------------------------------------------------
            STOP_COND: begin
                sda_oe <= 1; // SDA low
                scl_oe <= 0; // SCL high
                if (tick) begin
                    sda_oe <= 0; // SDA high
                    busy <= 0;
                    state <= IDLE;
                end
            end

        endcase
    end
end

endmodule
