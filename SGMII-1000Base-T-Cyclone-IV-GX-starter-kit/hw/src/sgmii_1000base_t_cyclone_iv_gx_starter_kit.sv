/**
 *  File:               sgmii_1000base_t_cyclone_iv_gx_starter_kit.sv
 *  Modules:            sgmii_1000base_t_cyclone_iv_gx_starter_kit
 *  Start design:       24.05.2021
 *  Last revision:      14.07.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  SGMII 1000Base-T example of using the "verilog-ethernet" library on Cyclone IV GX starter-kit
 *  Intel Cyclone IV GX (EP4CGX15BF14C8) FPGA
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
 *      24.05.2021              Create first versions of modules: "sgmii_1000base_t_cyclone_iv_gx_starter_kit" - (Vadim A. Lukinov)
 *
 */
`ifndef SGMII_1000BASE_T_CYCLONE_IV_GX_STARTER_KIT_SV_
`define SGMII_1000BASE_T_CYCLONE_IV_GX_STARTER_KIT_SV_


/**
 *  module - "sgmii_1000base_t_cyclone_iv_gx_starter_kit"
 *  SGMII 1000Base-T example of using the "verilog-ethernet" library on Cyclone IV GX starter-kit Top module
 *
 */
module sgmii_1000base_t_cyclone_iv_gx_starter_kit
#(
    parameter FPGA_REFERENCE_CLOCK_FREQUENCY = 125000000,
    parameter FPGA_RESET_DELAY_US = 20000,
    parameter FPGA_RESET_DELAY_TICKS = (FPGA_REFERENCE_CLOCK_FREQUENCY / 1000000) * FPGA_RESET_DELAY_US
)(
    input logic i_clock,                                                                            // 50 MHz clock
    input logic i_ref_clock,                                                                        // 125 MHz ethernet reference clock

    output logic o_phy_reset_n,
    input logic i_phy_rx_serial_data,
    output logic o_phy_tx_serial_data,

    output logic[3 : 0] o_led
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

    logic clock;
    logic ref_clock;

    bit reset;
    bit reset_counter_en;
    bit[FPGA_RESET_COUNTER_WIDTH - 1 : 0] reset_counter;

    logic phy_reset_n;

    logic tx_pcs_reset_syncronizer_async_reset_n;
    logic tx_pcs_reset_syncronizer_sync_reset_n;

    logic rx_pcs_reset_syncronizer_async_reset_n;
    logic rx_pcs_reset_syncronizer_sync_reset_n;

    logic triple_speed_ethernet_tx_clk;
    logic triple_speed_ethernet_rx_clk;
    logic triple_speed_ethernet_reset_tx_clk;
    logic triple_speed_ethernet_reset_rx_clk;

    logic triple_speed_ethernet_reg_rd;
    logic triple_speed_ethernet_reg_wr;
    logic triple_speed_ethernet_reconfig_clk;
    logic triple_speed_ethernet_reconfig_busy;

    logic phy_gmii_clk_en;
    logic[7 : 0] phy_gmii_rxd;
    logic phy_gmii_rx_dv;
    logic phy_gmii_rx_er;
    logic[7 : 0] phy_gmii_txd;
    logic phy_gmii_tx_en;
    logic phy_gmii_tx_er;

    bit[47 : 0] local_mac;
    bit[31 : 0] local_ip;
    bit[31 : 0] gateway_ip;
    bit[31 : 0] subnet_mask;
    bit[15 : 0] udp_dest_port;

    logic[3 : 0] led;
    logic[3 : 0] led_n;

    /// - Logic description ------------------------------------------------------------------------

    always_comb clock = i_clock;
    always_comb ref_clock = i_ref_clock;

    always_ff @(posedge ref_clock) reset <= reset_counter_en;

    always_comb reset_counter_en = reset_counter != FPGA_RESET_COUNTER_MODULE - 1;
    always_ff @(posedge ref_clock) begin
        if (reset_counter_en)
            reset_counter <= reset_counter + 1'b1;
    end

    always_comb tx_pcs_reset_syncronizer_async_reset_n = ~reset;
    always_comb rx_pcs_reset_syncronizer_async_reset_n = ~reset;

    always_comb triple_speed_ethernet_reconfig_clk = 1'b0;
    always_comb triple_speed_ethernet_reconfig_busy = 1'b0;
    always_comb triple_speed_ethernet_reg_rd = 1'b0;
    always_comb triple_speed_ethernet_reg_wr = 1'b0;

    always_comb triple_speed_ethernet_reset_tx_clk = ~tx_pcs_reset_syncronizer_sync_reset_n;
    always_comb triple_speed_ethernet_reset_rx_clk = ~rx_pcs_reset_syncronizer_sync_reset_n;

    always_comb phy_gmii_clk_en = 1'b1;

    always_comb local_mac = LOCAL_MAC;
    always_comb local_ip = LOCAL_IP;
    always_comb gateway_ip = GATEWAY_IP;
    always_comb subnet_mask = SUBNET_MASK;
    always_comb udp_dest_port = UDP_DEST_PORT;

    always_comb led[0] = 1'b0;
    always_comb led[1] = 1'b0;
    always_comb led[2] = 1'b0;
    always_comb led[3] = 1'b0;
    always_comb led_n = ~led;

    /// - External modules -------------------------------------------------------------------------

    // Tx PCS reset syncronizer
    reset_syncronizer tx_pcs_reset_syncronizer_i (
        .i_clock(triple_speed_ethernet_tx_clk),
        .i_async_reset_n(tx_pcs_reset_syncronizer_async_reset_n),
        .o_sync_reset_n(tx_pcs_reset_syncronizer_sync_reset_n)
    );

    // Rx PCS reset syncronizer
    reset_syncronizer rx_pcs_reset_syncronizer_i (
        .i_clock(triple_speed_ethernet_rx_clk),
        .i_async_reset_n(rx_pcs_reset_syncronizer_async_reset_n),
        .o_sync_reset_n(rx_pcs_reset_syncronizer_sync_reset_n)
    );

    // SGMII to GMII converter
    triple_speed_ethernet sgmii_to_gmii_converter_i (
        .ref_clk(ref_clock),
        .gxb_cal_blk_clk(ref_clock),
        .clk(ref_clock),
        .reset(reset),
        .reg_addr(),
        .reg_data_out(),
        .reg_rd(triple_speed_ethernet_reg_rd),
        .reg_data_in(),
        .reg_wr(triple_speed_ethernet_reg_wr),
        .reg_busy(),
        .tx_clk(triple_speed_ethernet_tx_clk),
        .rx_clk(triple_speed_ethernet_rx_clk),
        .reset_tx_clk(triple_speed_ethernet_reset_tx_clk),
        .reset_rx_clk(triple_speed_ethernet_reset_rx_clk),
        .gmii_rx_dv(phy_gmii_rx_dv),
        .gmii_rx_d(phy_gmii_rxd),
        .gmii_rx_err(phy_gmii_rx_er),
        .gmii_tx_en(phy_gmii_tx_en),
        .gmii_tx_d(phy_gmii_txd),
        .gmii_tx_err(phy_gmii_tx_er),
        .led_crs(),
        .led_link(),
        .led_panel_link(),
        .led_col(),
        .led_an(),
        .led_char_err(),
        .led_disp_err(),
        .rx_recovclkout(),
        .reconfig_clk(triple_speed_ethernet_reconfig_clk),
        .reconfig_togxb(),
        .reconfig_fromgxb(),
        .reconfig_busy(triple_speed_ethernet_reconfig_busy),
        .txp(o_phy_tx_serial_data),
        .rxp(i_phy_rx_serial_data)
    );

    fpga_core fpga_core_i (
        // Clock: 125MHz
        .clk(ref_clock),
        // Synchronous reset
        .rst(reset),

        // Ethernet configuration parameters
        .local_mac(local_mac),
        .local_ip(local_ip),
        .gateway_ip(gateway_ip),
        .subnet_mask(subnet_mask),
        .udp_dest_port(udp_dest_port),

        // Ethernet PHY: 1000BASE-T GMII
        .phy_gmii_clk(ref_clock),
        .phy_gmii_rst(reset),
        .phy_gmii_clk_en(phy_gmii_clk_en),
        .phy_gmii_rxd(phy_gmii_rxd),
        .phy_gmii_rx_dv(phy_gmii_rx_dv),
        .phy_gmii_rx_er(phy_gmii_rx_er),
        .phy_gmii_txd(phy_gmii_txd),
        .phy_gmii_tx_en(phy_gmii_tx_en),
        .phy_gmii_tx_er(phy_gmii_tx_er),
        .phy_reset_n(phy_reset_n),
        .phy_int_n()
    );

    /// - Outputs ----------------------------------------------------------------------------------

    always_comb o_phy_reset_n = phy_reset_n;

    always_comb o_led = led_n;

endmodule


`endif // SGMII_1000BASE_T_CYCLONE_IV_GX_STARTER_KIT_SV_

