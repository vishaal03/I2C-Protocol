// =============================================================
// I2C Bus Top-Level Module (SystemVerilog Version)
// =============================================================
timeunit 1ns;
timeprecision 1ps;

module I2C_BUS (
    // ----------------------------------------------------------
    // Physical I2C Lines
    // ----------------------------------------------------------
    inout  wire SDA_PIN,  // Single physical Data line
    inout  wire SCL_PIN,  // Single physical Clock line
    
    // ----------------------------------------------------------
    // Global Signals
    // ----------------------------------------------------------
    input  logic clk,
    input  logic rst,
    
    // ----------------------------------------------------------
    // Monitoring/Debugging Outputs (Example for Peripheral 0)
    // ----------------------------------------------------------
    output logic [7:0] P0_Rx_Data,
    output logic [6:0] P0_Address
);

    // ==========================================================
    // 1. SHARED I2C BUS NETS
    // ==========================================================
    // Internal nets representing voltage levels on the shared bus.
    logic SDA_NET = 1'b1; // Bus starts HIGH (pulled up)
    logic SCL_NET = 1'b1; // Bus starts HIGH (pulled up)

    // ==========================================================
    // 2. DEVICE I/O WIRES (Tri-state drivers)
    // ==========================================================
    // Controller tri-state outputs
    logic C0_SDA_DRV, C0_SCL_DRV;
    logic C1_SDA_DRV, C1_SCL_DRV;
    logic C2_SDA_DRV, C2_SCL_DRV;

    // Peripheral tri-state outputs
    logic P0_SDA_DRV, P0_SCL_DRV;
    logic P1_SDA_DRV, P1_SCL_DRV;
    logic P2_SDA_DRV, P2_SCL_DRV;

    // ==========================================================
    // 3. PHYSICAL PIN CONNECTION AND BUS RESOLUTION
    // ==========================================================

    // Physical pins reflect the resolved bus state
    assign SDA_PIN = SDA_NET; 
    assign SCL_PIN = SCL_NET;

    // Bus resolution: line pulled LOW if ANY device drives '0'
    assign SDA_NET = (C0_SDA_DRV == 1'b0) || (C1_SDA_DRV == 1'b0) || (C2_SDA_DRV == 1'b0) ||
                     (P0_SDA_DRV == 1'b0) || (P1_SDA_DRV == 1'b0) || (P2_SDA_DRV == 1'b0)
                     ? 1'b0 : 1'b1;

    assign SCL_NET = (C0_SCL_DRV == 1'b0) || (C1_SCL_DRV == 1'b0) || (C2_SCL_DRV == 1'b0) ||
                     (P0_SCL_DRV == 1'b0) || (P1_SCL_DRV == 1'b0) || (P2_SCL_DRV == 1'b0)
                     ? 1'b0 : 1'b1;

    // ==========================================================
    // 4. CONTROLLER INSTANTIATIONS (3 Controllers)
    // ==========================================================
    I2C_Controller C0 (
        .clk(clk), .rst(rst),
        .SDA(SDA_NET),         
        .SCL(SCL_NET),         
        .SDA_driver(C0_SDA_DRV),
        .SCL_driver(C0_SCL_DRV)
        // Add controller-specific ports as needed
    );

    I2C_Controller C1 (
        .clk(clk), .rst(rst),
        .SDA(SDA_NET),
        .SCL(SCL_NET),
        .SDA_driver(C1_SDA_DRV),
        .SCL_driver(C1_SCL_DRV)
    );

    I2C_Controller C2 (
        .clk(clk), .rst(rst),
        .SDA(SDA_NET),
        .SCL(SCL_NET),
        .SDA_driver(C2_SDA_DRV),
        .SCL_driver(C2_SCL_DRV)
    );

    // ==========================================================
    // 5. PERIPHERAL INSTANTIATIONS (3 Peripherals)
    // ==========================================================
    I2C_Peripheral #(.I2C_ADDRESS(7'h42)) P0 (
        .clk(clk), .rst(rst),
        .SDA(SDA_NET),         
        .SCL(SCL_NET),         
        .SDA_driver(P0_SDA_DRV),
        .SCL_driver(P0_SCL_DRV),
        .Rx_Data(P0_Rx_Data),
        .Rx_Addr(P0_Address)
    );

    I2C_Peripheral #(.I2C_ADDRESS(7'h2A)) P1 (
        .clk(clk), .rst(rst),
        .SDA(SDA_NET),
        .SCL(SCL_NET),
        .SDA_driver(P1_SDA_DRV),
        .SCL_driver(P1_SCL_DRV)
    );

    I2C_Peripheral #(.I2C_ADDRESS(7'h5C)) P2 (
        .clk(clk), .rst(rst),
        .SDA(SDA_NET),
        .SCL(SCL_NET),
        .SDA_driver(P2_SDA_DRV),
        .SCL_driver(P2_SCL_DRV)
    );

endmodule
