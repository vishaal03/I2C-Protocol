`timescale 1ns/1ps


module I2C_system_TB();

    // ------------------------------------------------------------------------
    // PARAMETERS
    // ------------------------------------------------------------------------
    parameter BYTES_SEND_LOG    = 2;   // up to 3 bytes
    parameter BYTES_RECEIVE_LOG = 2;
    parameter BITS_SEND_MAX     = ((2**BYTES_SEND_LOG)-1) << 3;

    // ------------------------------------------------------------------------
    // SIGNAL DECLARATIONS
    // ------------------------------------------------------------------------
    logic clk;
    logic rst;

    // Shared open-drain I2C lines
    tri1 SCL;
    tri1 SDA;

    // Master 1
    logic start_1;
    logic [BITS_SEND_MAX-1:0] data_send_1;
    logic [BYTES_SEND_LOG-1:0] num_bytes_send_1;
    logic [BYTES_RECEIVE_LOG-1:0] num_bytes_receive_1;
    logic [7:0] addr_target_1;

    // Master 2
    logic start_2;
    logic [BITS_SEND_MAX-1:0] data_send_2;
    logic [BYTES_SEND_LOG-1:0] num_bytes_send_2;
    logic [BYTES_RECEIVE_LOG-1:0] num_bytes_receive_2;
    logic [7:0] addr_target_2;

    // Master 3
    logic start_3;
    logic [BITS_SEND_MAX-1:0] data_send_3;
    logic [BYTES_SEND_LOG-1:0] num_bytes_send_3;
    logic [BYTES_RECEIVE_LOG-1:0] num_bytes_receive_3;
    logic [7:0] addr_target_3;

    // ------------------------------------------------------------------------
    // DEVICE UNDER TEST (DUT)
    // ------------------------------------------------------------------------
    I2C_top #(
        .BYTES_SEND_LOG(BYTES_SEND_LOG),
        .BYTES_RECEIVE_LOG(BYTES_RECEIVE_LOG)
    ) dut (
        .clk(clk),
        .rst(rst),

        // Master interfaces
        .start_1(start_1),
        .data_send_1(data_send_1),
        .num_bytes_send_1(num_bytes_send_1),
        .num_bytes_receive_1(num_bytes_receive_1),
        .addr_target_1(addr_target_1),

        .start_2(start_2),
        .data_send_2(data_send_2),
        .num_bytes_send_2(num_bytes_send_2),
        .num_bytes_receive_2(num_bytes_receive_2),
        .addr_target_2(addr_target_2),

        .start_3(start_3),
        .data_send_3(data_send_3),
        .num_bytes_send_3(num_bytes_send_3),
        .num_bytes_receive_3(num_bytes_receive_3),
        .addr_target_3(addr_target_3),

        // Shared Bus
        .SCL(SCL),
        .SDA(SDA)
    );

    // ------------------------------------------------------------------------
    // CLOCK GENERATION (50 MHz)
    // ------------------------------------------------------------------------
    always #10 clk = ~clk; // 20ns period = 50MHz

    // ------------------------------------------------------------------------
    // STIMULUS SEQUENCE
    // ------------------------------------------------------------------------
    initial begin
        // Initialize
        clk = 0;
        rst = 0;
        start_1 = 0;
        start_2 = 0;
        start_3 = 0;

        // Hold reset
        #100;
        rst = 1;
        #200;

        // ======================================================
        // TEST 1: Master 1 writes to Target 1 (Address 0x47)
        // ======================================================
        $display("TEST 1: Master 1 → Target 1 WRITE (2 bytes)");
        data_send_1 <= 16'hA5C3;
        addr_target_1 <= 8'b10001110; // 0x47 + write
        num_bytes_send_1 <= 2;
        num_bytes_receive_1 <= 0;
        start_1 <= 1;
        #200;
        start_1 <= 0;

        #100000; // Wait

        // ======================================================
        // TEST 2: Master 2 writes to Target 2 (Address 0x4F)
        // ======================================================
        $display("TEST 2: Master 2 → Target 2 WRITE (3 bytes)");
        data_send_2 <= 24'h123456;
        addr_target_2 <= 8'b10011110; // 0x4F + write
        num_bytes_send_2 <= 3;
        num_bytes_receive_2 <= 0;
        start_2 <= 1;
        #200;
        start_2 <= 0;

        #120000;

        // ======================================================
        // TEST 3: Master 3 tries to access UNKNOWN Target
        // ======================================================
        $display("TEST 3: Master 3 → Unknown Target (no ACK)");
        data_send_3 <= 16'hFACE;
        addr_target_3 <= 8'b11111110; // unknown
        num_bytes_send_3 <= 2;
        num_bytes_receive_3 <= 0;
        start_3 <= 1;
        #200;
        start_3 <= 0;

        #150000;

        // ======================================================
        // TEST 4: Master 1 READ from Target 2 (Address 0x4F)
        // ======================================================
        $display("TEST 4: Master 1 ← Target 2 READ (2 bytes)");
        addr_target_1 <= 8'b10011111; // 0x4F + read
        num_bytes_send_1 <= 0;
        num_bytes_receive_1 <= 2;
        start_1 <= 1;
        #200;
        start_1 <= 0;

        #150000;

        // ======================================================
        // TEST 5: Arbitration check (M1 + M2 start together)
        // ======================================================
        $display("TEST 5: Arbitration (M1 & M2 start same time)");
        data_send_1 <= 16'h0F0F;
        addr_target_1 <= 8'b10001110;
        num_bytes_send_1 <= 2;

        data_send_2 <= 16'hABCD;
        addr_target_2 <= 8'b10011110;
        num_bytes_send_2 <= 2;

        // both start simultaneously
        start_1 <= 1;
        start_2 <= 1;
        #200;
        start_1 <= 0;
        start_2 <= 0;

        #300000;

        $display("✅ Simulation Complete.");
        $stop;
    end

    // ------------------------------------------------------------------------
    // MONITORING
    // ------------------------------------------------------------------------
    initial begin
        $dumpfile("I2C_system.vcd");
        $dumpvars(0, I2C_system_TB);

        $display("=====================================================");
        $display(" Multi-Master / Multi-Target I2C Simulation Started ");
        $display("=====================================================");
        $display("Time(ns) | Master | Operation | Target | Data");
        $display("-----------------------------------------------------");
    end

endmodule


