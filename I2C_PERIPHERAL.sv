

module target_I2C #(
    parameter [6:0] ADDR_TARGET = 7'b1000111,   // Target address
    parameter BYTES_SEND   = 2,                 // Bytes target can send (read mode)
    parameter BYTES_RECEIVE = 2                 // Bytes target can receive (write mode)
)(
    input  logic clk,
    input  logic rst,

    // Predefined data to send back to master
    input  logic [(BYTES_SEND*8)-1:0] data_send,
    output logic [(BYTES_RECEIVE*8)-1:0] data_received,

    // I2C Bus (open-drain)
    inout  tri1 SDA_bidir,
    inout  tri1 SCL_bidir,

    // Active-high open-drain control signals
    output logic sda_drive_low,
    output logic scl_drive_low
);

    // =========================================================================
    // INTERNAL SIGNALS AND REGISTERS
    // =========================================================================
    typedef enum logic [3:0] {
        IDLE,
        ADDR_RECV,
        ACK_ADDR,
        RECV_BYTE,
        SEND_BYTE,
        ACK_PHASE,
        STOP_WAIT
    } state_t;

    state_t state, next_state;

    logic [7:0] bit_cnt;
    logic [7:0] byte_cnt;
    logic [7:0] rx_shift;
    logic [7:0] tx_shift;

    logic rw_bit;                // 0 = Write (Master→Slave), 1 = Read (Slave→Master)
    logic addr_match;
    logic scl_prev;
    logic start_detect, stop_detect;

    // SDA and SCL sampling
    logic SDA_sync, SCL_sync;
    always_ff @(posedge clk) begin
        SDA_sync <= SDA_bidir;
        SCL_sync <= SCL_bidir;
    end

    // =========================================================================
    // START and STOP condition detection
    // =========================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_prev <= 1;
            start_detect <= 0;
            stop_detect  <= 0;
        end else begin
            scl_prev <= SCL_sync;
            start_detect <= (SCL_sync && SDA_sync == 0 && SDA_sync !== SDA_bidir);
            stop_detect  <= (SCL_sync && SDA_sync && SDA_sync !== SDA_bidir);
        end
    end

    // =========================================================================
    // MAIN STATE MACHINE
    // =========================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            sda_drive_low <= 0;
            scl_drive_low <= 0;
            bit_cnt <= 0;
            byte_cnt <= 0;
            rx_shift <= 0;
            tx_shift <= 0;
            addr_match <= 0;
            rw_bit <= 0;
            data_received <= 0;
        end else begin
            case (state)

                // -------------------------------------------------------------
                // IDLE: Wait for START condition
                // -------------------------------------------------------------
                IDLE: begin
                    sda_drive_low <= 0;
                    scl_drive_low <= 0;
                    if (start_detect)
                        state <= ADDR_RECV;
                end

                // -------------------------------------------------------------
                // RECEIVE ADDRESS + RW bit
                // -------------------------------------------------------------
                ADDR_RECV: begin
                    if (SCL_sync == 1'b1) begin
                        rx_shift <= {rx_shift[6:0], SDA_bidir};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            rw_bit <= SDA_bidir;
                            addr_match <= (rx_shift[7:1] == ADDR_TARGET);
                            bit_cnt <= 0;
                            state <= ACK_ADDR;
                        end
                    end
                end

                // -------------------------------------------------------------
                // ACKNOWLEDGE ADDRESS (if match)
                // -------------------------------------------------------------
                ACK_ADDR: begin
                    if (addr_match) begin
                        if (SCL_sync == 0)
                            sda_drive_low <= 1; // Drive ACK low
                        else if (SCL_sync == 1)
                            sda_drive_low <= 0; // Release SDA after ACK
                        if (rw_bit)
                            state <= SEND_BYTE;  // Master reading from target
                        else
                            state <= RECV_BYTE;  // Master writing to target
                    end else begin
                        state <= IDLE; // Not for us
                    end
                end

                // -------------------------------------------------------------
                // RECEIVE BYTE (WRITE MODE)
                // -------------------------------------------------------------
                RECV_BYTE: begin
                    if (SCL_sync == 1'b1) begin
                        rx_shift <= {rx_shift[6:0], SDA_bidir};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            data_received <= {data_received[(BYTES_RECEIVE*8)-9:0], rx_shift};
                            bit_cnt <= 0;
                            byte_cnt <= byte_cnt + 1;
                            state <= ACK_PHASE;
                        end
                    end
                end

                // -------------------------------------------------------------
                // SEND BYTE (READ MODE)
                // -------------------------------------------------------------
                SEND_BYTE: begin
                    if (SCL_sync == 0) begin
                        sda_drive_low <= ~tx_shift[7];
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            bit_cnt <= 0;
                            byte_cnt <= byte_cnt + 1;
                            state <= ACK_PHASE;
                        end
                    end
                end

                // -------------------------------------------------------------
                // ACK PHASE
                // -------------------------------------------------------------
                ACK_PHASE: begin
                    sda_drive_low <= 0; // Release SDA to read ACK/NACK
                    if (stop_detect)
                        state <= STOP_WAIT;
                    else if (rw_bit && byte_cnt < BYTES_SEND)
                        state <= SEND_BYTE;
                    else if (!rw_bit && byte_cnt < BYTES_RECEIVE)
                        state <= RECV_BYTE;
                    else
                        state <= STOP_WAIT;
                end

                // -------------------------------------------------------------
                // WAIT FOR STOP
                // -------------------------------------------------------------
                STOP_WAIT: begin
                    if (stop_detect) begin
                        sda_drive_low <= 0;
                        state <= IDLE;
                        bit_cnt <= 0;
                        byte_cnt <= 0;
                    end
                end
            endcase
        end
    end

endmodule


