
module master_I2C #(
    parameter TLOW  = 250,   // SCL low time (ns or simulation cycles)
    parameter THIGH = 180,   // SCL high time
    parameter BYTES_SEND_LOG    = 2,
    parameter BYTES_RECEIVE_LOG = 2,
    parameter BITS_SEND_MAX     = ((2**BYTES_SEND_LOG)-1) << 3
)(
    input  logic clk,
    input  logic rst,

    // Master start command and grant
    input  logic start_request,     // request to start transaction
    input  logic grant,             // grant from arbiter

    // Target information and data buffers
    input  logic [7:0] addr_target, // 7-bit address + R/W bit controlled internally
    input  logic [BYTES_SEND_LOG-1:0] num_bytes_send,
    input  logic [BYTES_RECEIVE_LOG-1:0] num_bytes_receive,
    input  logic [BITS_SEND_MAX-1:0] data_send,

    // I2C Bus (open-drain)
    inout  tri1 SDA_bidir,
    inout  tri1 SCL_bidir,

    // Active-high signals to drive bus low
    output logic sda_drive_low,
    output logic scl_drive_low,

    // Status outputs
    output logic busy,
    output logic ack_error
);

    // =========================================================================
    // INTERNAL SIGNALS
    // =========================================================================
    typedef enum logic [3:0] {
        IDLE,
        START_COND,
        SEND_ADDR,
        SEND_BYTE,
        READ_BYTE,
        ACK_PHASE,
        STOP_COND,
        DONE
    } state_t;

    state_t state, next_state;

    logic [7:0] tx_shift;
    logic [7:0] rx_shift;
    logic [3:0] bit_cnt;
    logic [7:0] byte_cnt;

    logic scl_int, sda_int;
    logic scl_tick, scl_level;
    logic start_pulse;
    logic scl_enable;

    logic [15:0] timer;

    assign SDA_bidir = sda_drive_low ? 1'b0 : 1'bz;
    assign SCL_bidir = scl_drive_low ? 1'b0 : 1'bz;

    assign busy = (state != IDLE && state != DONE);

    // =========================================================================
    // CLOCK GENERATION (for SCL)
    // =========================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 0;
            scl_tick <= 0;
            scl_level <= 1;
        end else if (scl_enable) begin
            timer <= timer + 1;
            if (scl_level && timer >= THIGH) begin
                scl_level <= 0;
                timer <= 0;
                scl_tick <= 1;
            end else if (!scl_level && timer >= TLOW) begin
                scl_level <= 1;
                timer <= 0;
                scl_tick <= 1;
            end else begin
                scl_tick <= 0;
            end
        end else begin
            scl_level <= 1;
            scl_tick <= 0;
            timer <= 0;
        end
    end

    // =========================================================================
    // STATE MACHINE
    // =========================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_request && grant)
                    next_state = START_COND;
            end

            START_COND: begin
                next_state = SEND_ADDR;
            end

            SEND_ADDR: begin
                if (bit_cnt == 8 && scl_tick)
                    next_state = ACK_PHASE;
            end

            ACK_PHASE: begin
                if (scl_tick)
                    next_state = (ack_error) ? STOP_COND : SEND_BYTE;
            end

            SEND_BYTE: begin
                if (bit_cnt == 8 && scl_tick) begin
                    if (byte_cnt >= num_bytes_send)
                        next_state = STOP_COND;
                    else
                        next_state = ACK_PHASE;
                end
            end

            STOP_COND: begin
                next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

    // =========================================================================
    // OUTPUT CONTROL LOGIC (SDA/SCL open-drain drivers)
    // =========================================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sda_drive_low <= 0;
            scl_drive_low <= 0;
            bit_cnt <= 0;
            byte_cnt <= 0;
            tx_shift <= 0;
            ack_error <= 0;
            scl_enable <= 0;
        end else begin
            case (state)
                IDLE: begin
                    sda_drive_low <= 0;
                    scl_drive_low <= 0;
                    scl_enable <= 0;
                    ack_error <= 0;
                    bit_cnt <= 0;
                    byte_cnt <= 0;
                end

                START_COND: begin
                    // Generate start: SDA goes low while SCL is high
                    sda_drive_low <= 1;
                    scl_drive_low <= 0;
                    scl_enable <= 1;
                    tx_shift <= {addr_target[6:0], 1'b0}; // Write mode
                    bit_cnt <= 0;
                end

                SEND_ADDR, SEND_BYTE: begin
                    scl_enable <= 1;
                    if (scl_tick) begin
                        // Drive SDA on SCL falling edge
                        sda_drive_low <= ~tx_shift[7];
                        tx_shift <= {tx_shift[6:0], 1'b0};
                        bit_cnt <= bit_cnt + 1;
                    end
                end

                ACK_PHASE: begin
                    scl_enable <= 1;
                    sda_drive_low <= 0; // Release SDA to read ACK
                    if (scl_tick) begin
                        if (SDA_bidir == 1'b1)
                            ack_error <= 1;
                    end
                end

                STOP_COND: begin
                    // SDA goes high while SCL is high
                    sda_drive_low <= 0;
                    scl_drive_low <= 0;
                    scl_enable <= 0;
                end

                DONE: begin
                    sda_drive_low <= 0;
                    scl_drive_low <= 0;
                    scl_enable <= 0;
                end
            endcase
        end
    end

endmodule
