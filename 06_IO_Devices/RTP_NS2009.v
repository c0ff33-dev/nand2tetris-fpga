// =====================================================
// Simple I2C Master (Single Byte, 100kHz, 25MHz Clock)
// =====================================================
// Author: ChatGPT (GPT-5)
// Description:
// - Generates I2C start, stop, read, and write cycles
// - Fixed 25MHz input clock, 100kHz I2C clock
// - Single-byte transfer per start
// - Minimal control interface
// =====================================================

module i2c_master_simple (
    input  wire        clk,        // 25 MHz clock
    input  wire        reset_n,    // Active-low reset

    // I2C lines
    output reg         scl,        // I2C clock
    inout  wire        sda,        // I2C data (open-drain)

    // Control interface
    input  wire [6:0]  dev_addr,   // 7-bit I2C address
    input  wire [7:0]  wr_data,    // Byte to write
    output reg  [7:0]  rd_data,    // Byte read from slave
    input  wire        start,      // Begin transaction
    input  wire        rw,         // 0 = write, 1 = read
    output reg         busy,       // Busy flag
    output reg         ack_error   // ACK error flag
);

    // -------------------------------------------------
    // Clock divider for SCL = 100 kHz
    // -------------------------------------------------
    localparam integer DIVIDER = 25_000_000 / (100_000 * 4); // 4 ticks per SCL period
    reg [9:0] clk_cnt;
    reg scl_en;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            clk_cnt <= 0;
            scl <= 1'b1;
            scl_en <= 1'b0;
        end else if (busy) begin
            if (clk_cnt == DIVIDER - 1) begin
                clk_cnt <= 0;
                scl <= ~scl;       // Toggle SCL every DIVIDER cycles
                scl_en <= 1'b1;    // Single-cycle enable
            end else begin
                clk_cnt <= clk_cnt + 1;
                scl_en <= 1'b0;
            end
        end else begin
            scl <= 1'b1;
            scl_en <= 1'b0;
        end
    end

    // -------------------------------------------------
    // SDA control (open-drain)
    // -------------------------------------------------
    reg sda_out;
    reg sda_oe;  // 1 = drive SDA low, 0 = release
    assign sda = sda_oe ? 1'b0 : 1'bz;
    wire sda_in = sda;

    // -------------------------------------------------
    // State machine
    // -------------------------------------------------
    localparam [3:0]
        IDLE   = 0,
        START  = 1,
        SEND_ADDR = 2,
        SEND_RW   = 3,
        ADDR_ACK  = 4,
        WRITE_DATA = 5,
        READ_DATA  = 6,
        DATA_ACK   = 7,
        STOP    = 8;

    reg [3:0] state;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;

    // -------------------------------------------------
    // FSM sequential
    // -------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            busy <= 0;
            ack_error <= 0;
            sda_oe <= 0;
            bit_cnt <= 0;
            rd_data <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    sda_oe <= 0;
                    if (start) begin
                        busy <= 1;
                        ack_error <= 0;
                        state <= START;
                    end
                end

                START: begin
                    // SDA goes low while SCL high → start condition
                    sda_oe <= 1;
                    shift_reg <= {dev_addr, rw}; // address + R/W
                    bit_cnt <= 7;
                    state <= SEND_ADDR;
                end

                SEND_ADDR: if (scl_en && ~scl) begin
                    sda_oe <= ~shift_reg[bit_cnt]; // drive bit
                    if (bit_cnt == 0)
                        state <= ADDR_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                end

                ADDR_ACK: if (scl_en && scl) begin
                    sda_oe <= 0; // release SDA
                    if (sda_in)
                        ack_error <= 1; // no ACK
                    if (!rw)
                        state <= WRITE_DATA;
                    else begin
                        bit_cnt <= 7;
                        rd_data <= 8'h00;
                        state <= READ_DATA;
                    end
                end

                WRITE_DATA: if (scl_en && ~scl) begin
                    sda_oe <= ~wr_data[bit_cnt];
                    if (bit_cnt == 0)
                        state <= DATA_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                end

                READ_DATA: if (scl_en && scl) begin
                    rd_data[bit_cnt] <= sda_in;
                    if (bit_cnt == 0)
                        state <= DATA_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                end

                DATA_ACK: if (scl_en && ~scl) begin
                    sda_oe <= (rw) ? 1 : 0; // NACK for read, release for write
                    state <= STOP;
                end

                STOP: begin
                    // SDA low while SCL high -> SDA high = STOP
                    if (scl_en && scl) begin
                        sda_oe <= 0;
                        busy <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule