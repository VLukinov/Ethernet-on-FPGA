/**
 *  File:               sfp_sgmii_1000base_t_arria10_som.sv
 *  Modules:            sfp_sgmii_1000base_t_arria10_som
 *  Start design:       14.07.2021
 *  Last revision:      14.07.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  SGMII 1000Base-T on SFP example of using the "verilog-ethernet" library on Arria V SoC dev-kit
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
 *      14.07.2021              Create first versions of modules: "sfp_sgmii_1000base_t_arria10_som" - (Vadim A. Lukinov)
 *
 */
`ifndef SFP_SGMII_1000BASE_T_ARRIA10_SOM_SV_
`define SFP_SGMII_1000BASE_T_ARRIA10_SOM_SV_


/**
 *  module - "sfp_sgmii_1000base_t_arria10_som"
 *  SGMII 1000Base-T on SFP example of using the "verilog-ethernet" library on Arria V SoC dev-kit
 *
 */
module sfp_sgmii_1000base_t_arria10_som
#(
    parameter FPGA_REFERENCE_CLOCK_FREQUENCY = 125000000,
    parameter FPGA_RESET_DELAY_US = 20000,
    parameter FPGA_RESET_DELAY_TICKS = (FPGA_REFERENCE_CLOCK_FREQUENCY / 1000000) * FPGA_RESET_DELAY_US
)(
    input logic i_ref_clock,

    input logic i_sfp_port0_rx_serial_data,
    output logic o_sfp_port0_tx_serial_data,

    input logic i_sfp_port0_los,
    input logic i_sfp_port0_tx_fault,
    input logic i_sfp_port0_mod0_prsnt_n,
    output logic o_sfp_port0_mod1_scl,
    output logic o_sfp_port0_mod2_sda,
    output logic o_sfp_port0_tx_disable,
    output logic[1 : 0] o_sfp_port0_rate_sel
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
    logic tx_serial_clk;

    bit reset;
    bit reset_counter_en;
    bit[FPGA_RESET_COUNTER_WIDTH - 1 : 0] reset_counter;

    logic xcvr_pll_locked;
    logic xcvr_pll_cal_busy;
    logic xcvr_pll_powerdown;

    logic xcvr_reset_rx_analogreset;
    logic xcvr_reset_rx_cal_busy;
    logic xcvr_reset_rx_digitalreset;
    logic xcvr_reset_rx_is_lockedtodata;
    logic xcvr_reset_rx_ready;

    logic xcvr_reset_tx_analogreset;
    logic xcvr_reset_tx_cal_busy;
    logic xcvr_reset_tx_digitalreset;
    logic xcvr_reset_tx_ready;

    logic rx_pcs_reset_syncronizer_async_reset_n;
    logic rx_pcs_reset_syncronizer_sync_reset_n;

    logic tx_pcs_reset_syncronizer_async_reset_n;
    logic tx_pcs_reset_syncronizer_sync_reset_n;

    logic triple_speed_ethernet_rx_clk;
    logic triple_speed_ethernet_tx_clk;
    logic triple_speed_ethernet_reset_rx_clk;
    logic triple_speed_ethernet_reset_tx_clk;

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

    /// - Logic description ------------------------------------------------------------------------

    always_comb clock = ref_clock;
    always_comb ref_clock = i_ref_clock;

    always_ff @(posedge clock) reset <= reset_counter_en;

    always_comb reset_counter_en = reset_counter != FPGA_RESET_COUNTER_MODULE - 1;
    always_ff @(posedge clock) begin
        if (reset_counter_en)
            reset_counter <= reset_counter + 1'b1;
    end

    always_comb rx_pcs_reset_syncronizer_async_reset_n = xcvr_reset_rx_ready;
    always_comb tx_pcs_reset_syncronizer_async_reset_n = xcvr_reset_tx_ready;

    always_comb triple_speed_ethernet_reset_rx_clk = ~rx_pcs_reset_syncronizer_sync_reset_n;
    always_comb triple_speed_ethernet_reset_tx_clk = ~tx_pcs_reset_syncronizer_sync_reset_n;

    always_comb phy_gmii_clk_en = 1'b1;

    always_comb local_mac = LOCAL_MAC;
    always_comb local_ip = LOCAL_IP;
    always_comb gateway_ip = GATEWAY_IP;
    always_comb subnet_mask = SUBNET_MASK;
    always_comb udp_dest_port = UDP_DEST_PORT;

    /// - External modules -------------------------------------------------------------------------

    // XCVR PLL
    xcvr_pll xcvr_pll_i (
        .pll_powerdown(xcvr_pll_powerdown),
        .pll_refclk0(ref_clock),
        .tx_serial_clk(tx_serial_clk),
        .pll_locked(xcvr_pll_locked),
        .pll_cal_busy(xcvr_pll_cal_busy)
    );

    // XCVR reset controller
    xcvr_reset_control xcvr_reset_control_i (
        .clock(clock),
        .pll_locked(xcvr_pll_locked),
        .pll_powerdown(xcvr_pll_powerdown),
        .pll_select(),
        .reset(reset),
        .rx_analogreset(xcvr_reset_rx_analogreset),
        .rx_cal_busy(xcvr_reset_rx_cal_busy),
        .rx_digitalreset(xcvr_reset_rx_digitalreset),
        .rx_is_lockedtodata(xcvr_reset_rx_is_lockedtodata),
        .rx_ready(xcvr_reset_rx_ready),
        .tx_analogreset(xcvr_reset_tx_analogreset),
        .tx_cal_busy(xcvr_reset_tx_cal_busy),
        .tx_digitalreset(xcvr_reset_tx_digitalreset),
        .tx_ready(xcvr_reset_tx_ready)
    );

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
        .reg_addr(),
        .reg_data_out(),
        .reg_rd(),
        .reg_data_in(),
        .reg_wr(),
        .reg_busy(),
        .clk(clock),
        .gmii_rx_dv(phy_gmii_rx_dv),
        .gmii_rx_d(phy_gmii_rxd),
        .gmii_rx_err(phy_gmii_rx_er),
        .gmii_tx_en(phy_gmii_tx_en),
        .gmii_tx_d(phy_gmii_txd),
        .gmii_tx_err(phy_gmii_tx_er),
        .rx_clk(triple_speed_ethernet_rx_clk),
        .reset_rx_clk(triple_speed_ethernet_reset_rx_clk),
        .ref_clk(ref_clock),
        .tx_clk(triple_speed_ethernet_tx_clk),
        .reset_tx_clk(triple_speed_ethernet_reset_tx_clk),
        .reset(reset),
        .rx_analogreset(xcvr_reset_rx_analogreset),
        .rx_cal_busy(xcvr_reset_rx_cal_busy),
        .rx_cdr_refclk(ref_clock),
        .rx_digitalreset(xcvr_reset_rx_digitalreset),
        .rx_is_lockedtodata(xcvr_reset_rx_is_lockedtodata),
        .rx_is_lockedtoref(),
        .rx_set_locktodata(),
        .rx_set_locktoref(),
        .rx_recovclkout(),
        .rxp(i_sfp_port0_rx_serial_data),
        .txp(o_sfp_port0_tx_serial_data),
        .led_crs(),
        .led_link(),
        .led_panel_link(),
        .led_col(),
        .led_an(),
        .led_char_err(),
        .led_disp_err(),
        .tx_analogreset(xcvr_reset_tx_analogreset),
        .tx_cal_busy(xcvr_reset_tx_cal_busy),
        .tx_digitalreset(xcvr_reset_tx_digitalreset),
        .tx_serial_clk(tx_serial_clk),
        .tx_clkena(1'b1),
        .rx_clkena(1'b1),
        .mii_rx_dv(),
        .mii_rx_d(),
        .mii_rx_err(),
        .mii_tx_en(),
        .mii_tx_d(),
        .mii_tx_err(),
        .mii_col(),
        .mii_crs(),
        .set_10(),
        .set_1000(),
        .set_100(),
        .hd_ena()
    );

    // UDP FPGA core
    fpga_core fpga_core_i (
        // Clock: 125MHz
        .clk(clock),
        // Synchronous reset
        .rst(reset),

        // Ethernet configuration parameters
        .local_mac(local_mac),
        .local_ip(local_ip),
        .gateway_ip(gateway_ip),
        .subnet_mask(subnet_mask),
        .udp_dest_port(udp_dest_port),

        // Ethernet PHY: 1000BASE-T GMII
        .phy_gmii_clk(clock),
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



endmodule


`endif // SFP_SGMII_1000BASE_T_ARRIA10_SOM_SV_

