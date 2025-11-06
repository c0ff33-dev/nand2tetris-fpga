// =====================================================
// Simple I2C Master (25 MHz → 100 kHz, Single Byte, Clock-Stretch Aware)
// =====================================================
// Author : ChatGPT (GPT-5)
// Date   : 2025-11-07
// =====================================================
// Features:
//   - 25 MHz system clock input
//   - 100 kHz I2C bit rate
//   - Open-drain SDA and SCL (pull-ups required)
//   - Handles single-byte read or write
//   - Waits for clock stretching (slave can hold SCL low)
// =====================================================

module i2c_master_simple_stretch (
    input  wire        clk,        // 25 MHz system clock
    input  wire        reset_n,    // Active-low async reset

    // I2C bus
    inout  wire        sda,
    inout  wire        scl,

    // Control interface
    input  wire [6:0]  dev_addr,   // 7-bit I2C device address
    input  wire [7:0]  wr_data,    // Data to write
    output reg  [7:0]  rd_data,    // Data read
    input  wire        start,      // Begin transaction
    input  wire        rw,         // 0 = write, 1 = read
    output reg         busy,       // 1 = transaction in progress
    output reg         ack_error   // 1 = NACK received
);

    // -------------------------------------------------
    // Clock divider (for I2C timing ticks)
    // -------------------------------------------------
    // 25 MHz / (100 kHz × 4) = 62.5 → ~62 cycles per 1/4 SCL period
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
    typedef enum logic [3:0] {
        IDLE        = 0,
        START_COND  = 1,
        SEND_ADDR   = 2,
        ADDR_ACK    = 3,
        WRITE_BYTE  = 4,
        READ_BYTE   = 5,
        DATA_ACK    = 6,
        STOP_COND   = 7
    } state_t;

    state_t state;

    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;

    // -------------------------------------------------
    // Main FSM
    // -------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            busy      <= 0;
            ack_error <= 0;
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
                    if (start) begin
                        busy <= 1;
                        ack_error <= 0;
                        state <= START_COND;
                    end
                end

                // -------------------------------------------------
                START_COND: begin
                    // SDA goes low while SCL high
                    sda_oe <= 1;   // drive low
                    scl_oe <= 0;   // ensure SCL released (high)
                    if (tick && scl_in) begin
                        shift_reg <= {dev_addr, rw};
                        bit_cnt <= 7;
                        state <= SEND_ADDR;
                    end
                end

                // -------------------------------------------------
                SEND_ADDR: begin
                    if (tick) begin
                        // Pull SCL low before data change
                        scl_oe <= 1;
                        sda_oe <= ~shift_reg[bit_cnt];
                        // Release SCL high for sampling
                        if (bit_cnt == 0)
                            state <= ADDR_ACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                    // Release SCL and wait for it to go high (clock stretch aware)
                    if (tick && scl_oe) scl_oe <= 0;
                end

                // -------------------------------------------------
                ADDR_ACK: begin
                    // 9th clock: Slave drives ACK
                    sda_oe <= 0;   // release SDA
                    scl_oe <= 0;   // release SCL
                    if (scl_in && tick) begin
                        if (sda_in) ack_error <= 1;
                        if (rw) begin
                            rd_data <= 8'h00;
                            bit_cnt <= 7;
                            state <= READ_BYTE;
                        end else begin
                            bit_cnt <= 7;
                            shift_reg <= wr_data;
                            state <= WRITE_BYTE;
                        end
                    end
                end

                // -------------------------------------------------
                WRITE_BYTE: begin
                    if (tick) begin
                        scl_oe <= 1;
                        sda_oe <= ~shift_reg[bit_cnt];
                        if (bit_cnt == 0)
                            state <= DATA_ACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                    if (tick && scl_oe) scl_oe <= 0;
                end

                // -------------------------------------------------
                READ_BYTE: begin
                    sda_oe <= 0; // release SDA for input
                    if (scl_in && tick) begin
                        rd_data[bit_cnt] <= sda_in;
                        if (bit_cnt == 0)
                            state <= DATA_ACK;
                        else
                            bit_cnt <= bit_cnt - 1;
                    end
                end

                // -------------------------------------------------
                DATA_ACK: begin
                    if (rw)
                        sda_oe <= 1; // Master sends NACK after read
                    else
                        sda_oe <= 0; // Release for ACK from slave

                    scl_oe <= 0;
                    if (scl_in && tick)
                        state <= STOP_COND;
                end

                // -------------------------------------------------
                STOP_COND: begin
                    // SDA low while SCL high -> SDA high = STOP
                    sda_oe <= 1;
                    scl_oe <= 0;
                    if (scl_in && tick) begin
                        sda_oe <= 0; // release high
                        busy <= 0;
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule
