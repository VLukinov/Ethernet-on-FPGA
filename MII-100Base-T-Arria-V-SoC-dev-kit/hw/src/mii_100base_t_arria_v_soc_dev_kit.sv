/**
 *  File:               mii_100base_t_arria_v_soc_dev_kit.sv
 *  Modules:            mii_100base_t_arria_v_soc_dev_kit
 *  Start design:       30.03.2021
 *  Last revision:      30.03.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  MII 100Base-T example of using the "verilog-ethernet" library on Arria V SoC dev-kit
 *  Intel Arria V (5ASTFD5K3F40I3) FPGA
 *  Copyright (c) 2021 Vadim A. Lukinov
 *
 *  Naming Conventions:
 *      parameter               "p_*"
 *      local parameter         "lp_*"
 *      input port              "i_*"
 *      output port             "o_*"
 *      active low signals:     "*_n"
 *      write enable:           "*_we"
 *      clock signals:          clock, clk
 *      reset signal:           reset_n, rst_n
 *
 *  History:
 *      30.03.2021              Create first versions of modules: "mii_100base_t_arria_v_soc_dev_kit" - (Vadim A. Lukinov)
 *
 */
`ifndef MII_100BASE_T_ARRIA_V_SOC_DEV_KIT_SV_
`define MII_100BASE_T_ARRIA_V_SOC_DEV_KIT_SV_


/**
 *  module - "mii_100base_t_arria_v_soc_dev_kit"
 *  MII 100Base-T example of using the "verilog-ethernet" library on Arria V SoC dev-kit Top module
 *
 */
module mii_100base_t_arria_v_soc_dev_kit
#(
    parameter FPGA_REFERENCE_CLOCK_FREQUENCY = 125000000,
    parameter FPGA_RESET_DELAY_US = 20000,
    parameter FPGA_RESET_DELAY_TICKS = (FPGA_REFERENCE_CLOCK_FREQUENCY / 1000000) * FPGA_RESET_DELAY_US
)(
    input logic i_ref_clock,

    output logic o_phy_reset_n,
    input logic i_phy_port0_rx_clk,
    input logic[3 : 0] i_phy_port0_rx_d,
    input logic i_phy_port0_rx_dv,
    input logic i_phy_port0_rx_er,
    input logic i_phy_port0_tx_clk,
    output logic[3 : 0] o_phy_port0_tx_d,
    output logic o_phy_port0_tx_en,
    output logic o_phy_port0_tx_er
);
    /// - Internal parameters & constants ----------------------------------------------------------

    localparam FPGA_RESET_COUNTER_MODULE = FPGA_RESET_DELAY_TICKS;
    localparam FPGA_RESET_COUNTER_WIDTH = $clog2(FPGA_RESET_COUNTER_MODULE);

    localparam bit[47 : 0] LOCAL_MAC =      48'h02_00_00_00_00_00;
    localparam bit[31 : 0] LOCAL_IP =       { 8'd192, 8'd168, 8'd1,   8'd128 };
    localparam bit[31 : 0] GATEWAY_IP =     { 8'd192, 8'd168, 8'd1,   8'd1 };
    localparam bit[31 : 0] SUBNET_MASK =    { 8'd255, 8'd255, 8'd255, 8'd0 };
    localparam bit[15 : 0] UDP_DEST_PORT =  16'd1234;

    /// - Internal logic ---------------------------------------------------------------------------

    logic ref_clock;

    bit reset;
    bit reset_counter_en;
    bit[FPGA_RESET_COUNTER_WIDTH - 1 : 0] reset_counter;

    bit[47 : 0] local_mac;
    bit[31 : 0] local_ip;
    bit[31 : 0] gateway_ip;
    bit[31 : 0] subnet_mask;
    bit[15 : 0] udp_dest_port;

    /// - Logic description ------------------------------------------------------------------------

    always_comb ref_clock = i_ref_clock;

    always_ff @(posedge ref_clock) reset <= reset_counter_en;

    always_comb reset_counter_en = reset_counter != FPGA_RESET_COUNTER_MODULE - 1;
    always_ff @(posedge ref_clock) begin
        if (reset_counter_en)
            reset_counter <= reset_counter + 1'b1;
    end

    always_comb local_mac = LOCAL_MAC;
    always_comb local_ip = LOCAL_IP;
    always_comb gateway_ip = GATEWAY_IP;
    always_comb subnet_mask = SUBNET_MASK;
    always_comb udp_dest_port = UDP_DEST_PORT;

    /// - External modules -------------------------------------------------------------------------

    fpga_core #(
        .TARGET("ALTERA")
    ) fpga_core_i (
        // Clock: 25MHz
        .clk(ref_clock),
        // Synchronous reset
        .rst(reset),

        // Ethernet configuration parameters
        .local_mac(local_mac),
        .local_ip(local_ip),
        .gateway_ip(gateway_ip),
        .subnet_mask(subnet_mask),
        .udp_dest_port(udp_dest_port),

        // Ethernet PHY: 100BASE-T MII (no GMII gtx_clk & no CRS, COL)
        .phy_rx_clk(i_phy_port0_rx_clk),
        .phy_rxd(i_phy_port0_rx_d),
        .phy_rx_dv(i_phy_port0_rx_dv),
        .phy_rx_er(i_phy_port0_rx_er),
        .phy_tx_clk(i_phy_port0_tx_clk),
        .phy_txd(o_phy_port0_tx_d),
        .phy_tx_en(o_phy_port0_tx_en),
        .phy_tx_er(o_phy_port0_tx_er),
        .phy_reset_n(o_phy_reset_n),
        .phy_col(),
        .phy_crs()
    );

    /// - Outputs ----------------------------------------------------------------------------------



endmodule


`endif // MII_100BASE_T_ARRIA_V_SOC_DEV_KIT_SV_

