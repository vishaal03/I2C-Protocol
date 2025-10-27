module I2C_top #(
    parameter BYTES_SEND_LOG    = 2,
    parameter BYTES_RECEIVE_LOG = 2,
    parameter BITS_SEND_MAX     = ((2**BYTES_SEND_LOG) - 1) << 3
)(
    input  logic clk,
    input  logic rst,

    // --- Master 1 interface ---
    input  logic start_1,
    input  logic [BITS_SEND_MAX-1:0] data_send_1,
    input  logic [BYTES_SEND_LOG-1:0] num_bytes_send_1,
    input  logic [BYTES_RECEIVE_LOG-1:0] num_bytes_receive_1,
    input  logic [7:0] addr_target_1,

    // --- Master 2 interface ---
    input  logic start_2,
    input  logic [BITS_SEND_MAX-1:0] data_send_2,
    input  logic [BYTES_SEND_LOG-1:0] num_bytes_send_2,
    input  logic [BYTES_RECEIVE_LOG-1:0] num_bytes_receive_2,
    input  logic [7:0] addr_target_2,

    // --- Master 3 interface ---
    input  logic start_3,
    input  logic [BITS_SEND_MAX-1:0] data_send_3,
    input  logic [BYTES_SEND_LOG-1:0] num_bytes_send_3,
    input  logic [BYTES_RECEIVE_LOG-1:0] num_bytes_receive_3,
    input  logic [7:0] addr_target_3,

    // --- Shared I2C Bus Lines ---
    inout tri1 SCL,
    inout tri1 SDA
);

    // =========================================================================
    // INTERNAL SIGNALS
    // =========================================================================
    logic [2:0] master_scl_drive_low;
    logic [2:0] master_sda_drive_low;
    logic [2:0] grant_master;

    logic [2:0] target_scl_drive_low;
    logic [2:0] target_sda_drive_low;

    // =========================================================================
    // SIMPLE PRIORITY-BASED ARBITER
    // =========================================================================
    always_comb begin
        grant_master = '{default:1'b0};
        if (start_1)
            grant_master = '{1'b1, 1'b0, 1'b0};
        else if (start_2)
            grant_master = '{1'b0, 1'b1, 1'b0};
        else if (start_3)
            grant_master = '{1'b0, 1'b0, 1'b1};
    end

    // =========================================================================
    // MASTER INSTANTIATIONS
    // =========================================================================

    master_I2C #(
        .TLOW(250),
        .THIGH(180),
        .BYTES_SEND_LOG(BYTES_SEND_LOG),
        .BYTES_RECEIVE_LOG(BYTES_RECEIVE_LOG)
    ) m1 (
        .rst(rst),
        .clk(clk),
        .start_request(start_1),
        .grant(grant_master[0]),
        .addr_target(addr_target_1),
        .num_bytes_send(num_bytes_send_1),
        .num_bytes_receive(num_bytes_receive_1),
        .data_send(data_send_1),
        .SDA_bidir(SDA),
        .SCL_bidir(SCL),
        .sda_drive_low(master_sda_drive_low[0]),
        .scl_drive_low(master_scl_drive_low[0])
    );

    master_I2C #(
        .TLOW(260),
        .THIGH(200),
        .BYTES_SEND_LOG(BYTES_SEND_LOG),
        .BYTES_RECEIVE_LOG(BYTES_RECEIVE_LOG)
    ) m2 (
        .rst(rst),
        .clk(clk),
        .start_request(start_2),
        .grant(grant_master[1]),
        .addr_target(addr_target_2),
        .num_bytes_send(num_bytes_send_2),
        .num_bytes_receive(num_bytes_receive_2),
        .data_send(data_send_2),
        .SDA_bidir(SDA),
        .SCL_bidir(SCL),
        .sda_drive_low(master_sda_drive_low[1]),
        .scl_drive_low(master_scl_drive_low[1])
    );

    master_I2C #(
        .TLOW(275),
        .THIGH(220),
        .BYTES_SEND_LOG(BYTES_SEND_LOG),
        .BYTES_RECEIVE_LOG(BYTES_RECEIVE_LOG)
    ) m3 (
        .rst(rst),
        .clk(clk),
        .start_request(start_3),
        .grant(grant_master[2]),
        .addr_target(addr_target_3),
        .num_bytes_send(num_bytes_send_3),
        .num_bytes_receive(num_bytes_receive_3),
        .data_send(data_send_3),
        .SDA_bidir(SDA),
        .SCL_bidir(SCL),
        .sda_drive_low(master_sda_drive_low[2]),
        .scl_drive_low(master_scl_drive_low[2])
    );

    // =========================================================================
    // SLAVE INSTANTIATIONS (3 Targets)
    // =========================================================================

    target_I2C #(
        .ADDR_TARGET(7'b1000111),
        .BYTES_SEND(2),
        .BYTES_RECEIVE(2)
    ) t1 (
        .rst(rst),
        .clk(clk),
        .data_send(16'b1100110011110000),
        .SCL_bidir(SCL),
        .SDA_bidir(SDA),
        .sda_drive_low(target_sda_drive_low[0]),
        .scl_drive_low(target_scl_drive_low[0])
    );

    target_I2C #(
        .ADDR_TARGET(7'b1001110),
        .BYTES_SEND(2),
        .BYTES_RECEIVE(2)
    ) t2 (
        .rst(rst),
        .clk(clk),
        .data_send(16'b0011010111001111),
        .SCL_bidir(SCL),
        .SDA_bidir(SDA),
        .sda_drive_low(target_sda_drive_low[1]),
        .scl_drive_low(target_scl_drive_low[1])
    );

    target_I2C #(
        .ADDR_TARGET(7'b1010101),
        .BYTES_SEND(1),
        .BYTES_RECEIVE(3)
    ) t3 (
        .rst(rst),
        .clk(clk),
        .data_send(8'b10111011),
        .SCL_bidir(SCL),
        .SDA_bidir(SDA),
        .sda_drive_low(target_sda_drive_low[2]),
        .scl_drive_low(target_scl_drive_low[2])
    );

    // =========================================================================
    // WIRED-AND OPEN-DRAIN BUS COMBINATION
    // =========================================================================

    logic any_sda_pull_low;
    logic any_scl_pull_low;

    assign any_sda_pull_low = (|master_sda_drive_low) | (|target_sda_drive_low);
    assign any_scl_pull_low = (|master_scl_drive_low) | (|target_scl_drive_low);

    // Implement open-drain (wired-AND) logic for SDA and SCL
    assign SDA = any_sda_pull_low ? 1'b0 : 1'bz;
    assign SCL = any_scl_pull_low ? 1'b0 : 1'bz;

endmodule
