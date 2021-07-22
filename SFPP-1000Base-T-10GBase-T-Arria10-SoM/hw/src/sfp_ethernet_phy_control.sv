/**
 *  File:               sfp_ethernet_phy_control.sv
 *  Modules:            sfp_ethernet_phy_control
 *  Start design:       21.07.2021
 *  Last revision:      21.07.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  SFP && 1000Base-T/10GBase-T ethernet PHY controller on Arria 10
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
 *      21.07.2021              Create first versions of modules: "sfp_ethernet_phy_control" - (Vadim A. Lukinov)
 *
 */
`ifndef SFP_ETHERNET_PHY_CONTROL_SV_
`define SFP_ETHERNET_PHY_CONTROL_SV_


/**
 *  module - "sfp_ethernet_phy_control"
 *  SFP && 1000Base-T/10GBase-T ethernet PHY controller on Arria 10
 *
 */
module sfp_ethernet_phy_control
(
    input logic i_clock,
    input logic i_reset_n,

    input logic i_xcvr_1g_ref_clock,
    input logic i_xcvr_10g_ref_clock,

    input logic i_sfp_rx_serial_data,
    output logic o_sfp_tx_serial_data,

    input logic i_sfp_los,
    input logic i_sfp_tx_fault,
    input logic i_sfp_mod0_prsnt_n,
    output logic o_sfp_tx_disable,
    inout wire io_sfp_mod1_scl,
    inout wire io_sfp_mod2_sda,
    output logic[1 : 0] o_sfp_rate_sel,

    output logic o_gmii_clock,
    output logic o_gmii_rx_dv,
    output logic o_gmii_rx_err,
    output logic[7 : 0] o_gmii_rx_d,
    input logic i_gmii_tx_en,
    input logic i_gmii_tx_err,
    input logic[7 : 0] i_gmii_tx_d,

    output logic o_xgmii_clock,
    output logic[7 : 0][7 : 0] o_xgmii_rx_data,
    output logic[7 : 0] o_xgmii_rx_control,
    input logic[7 : 0][7 : 0] i_xgmii_tx_data,
    input logic[7 : 0] i_xgmii_tx_control
);
    /// - Internal parameters & constants ----------------------------------------------------------



    /// - Internal logic ---------------------------------------------------------------------------

    logic clock;
    logic reset;
    logic reset_n;

    logic xcvr_1g_ref_clock;
    logic xcvr_10g_ref_clock;

    logic sfp_los;
    logic sfp_tx_fault;
    logic sfp_mod0_prsnt_n;
    logic sfp_tx_disable;

    wire sfp_mod1_scl = 1'bZ;
    wire sfp_mod2_sda = 1'bZ;

    logic sfp_phy_ready;

    logic phy_reset;
    logic phy_reset_n;

    logic xcvr_1g_pll_locked;
    logic xcvr_1g_pll_cal_busy;
    logic xcvr_1g_pll_powerdown;
    logic xcvr_1g_tx_serial_clk;

    logic xcvr_10g_pll_locked;
    logic xcvr_10g_pll_cal_busy;
    logic xcvr_10g_pll_powerdown;
    logic xcvr_10g_tx_serial_clk;

    logic xcvr_pll_locked;
    logic xcvr_pll_powerdown;

    logic xcvr_rx_cal_busy;
    logic xcvr_rx_analogreset;
    logic xcvr_rx_digitalreset;
    logic xcvr_rx_is_lockedtodata;

    logic xcvr_tx_cal_busy;
    logic xcvr_tx_analogreset;
    logic xcvr_tx_digitalreset;

    logic xgmii_clock;
    logic xgmii_pll_locked;
    logic xgmii_pll_powerdown;
    logic xgmii_pll_cal_busy;

    logic[71 : 0] xgmii_tx_dc;
    logic[71 : 0] xgmii_rx_dc;

    logic[7 : 0][7 : 0] xgmii_tx_data;
    logic[7 : 0] xgmii_tx_control;

    logic[7 : 0][7 : 0] xgmii_rx_data;
    logic[7 : 0] xgmii_rx_control;

    /// - Logic description ------------------------------------------------------------------------

    always_comb clock = i_clock;
    always_comb reset = ~reset_n;
    always_comb reset_n = i_reset_n;

    always_comb xcvr_1g_ref_clock = i_xcvr_1g_ref_clock;
    always_comb xcvr_10g_ref_clock = i_xcvr_10g_ref_clock;

    always_comb sfp_los = i_sfp_los;
    always_comb sfp_tx_fault = i_sfp_tx_fault;
    always_comb sfp_mod0_prsnt_n = i_sfp_mod0_prsnt_n;
    always_comb sfp_tx_disable = 1'b0;

    always_comb sfp_phy_ready = ~(sfp_los | sfp_tx_fault | sfp_mod0_prsnt_n);
    always_comb phy_reset = ~phy_reset_n;

    always_comb xcvr_1g_pll_powerdown = xcvr_pll_powerdown;
    always_comb xcvr_10g_pll_powerdown = xcvr_pll_powerdown;
    always_comb xgmii_pll_powerdown = xcvr_pll_powerdown;

    always_comb xcvr_pll_locked = xcvr_1g_pll_locked & xcvr_10g_pll_locked & xgmii_pll_locked;

    always_comb xgmii_rx_data = {
        xgmii_rx_dc[70 : 63],
        xgmii_rx_dc[61 : 54],
        xgmii_rx_dc[52 : 45],
        xgmii_rx_dc[43 : 36],
        xgmii_rx_dc[34 : 27],
        xgmii_rx_dc[25 : 18],
        xgmii_rx_dc[16 : 9],
        xgmii_rx_dc[7 : 0]
    };

    always_comb xgmii_rx_control = {
        xgmii_rx_dc[71],
        xgmii_rx_dc[62],
        xgmii_rx_dc[53],
        xgmii_rx_dc[44],
        xgmii_rx_dc[35],
        xgmii_rx_dc[26],
        xgmii_rx_dc[17],
        xgmii_rx_dc[8]
    };

    always_comb xgmii_tx_data = i_xgmii_tx_data;
    always_comb xgmii_tx_control = i_xgmii_tx_control;

    always_comb xgmii_tx_dc = {
        xgmii_tx_control[7], xgmii_tx_data[7],
        xgmii_tx_control[6], xgmii_tx_data[6],
        xgmii_tx_control[5], xgmii_tx_data[5],
        xgmii_tx_control[4], xgmii_tx_data[4],
        xgmii_tx_control[3], xgmii_tx_data[3],
        xgmii_tx_control[2], xgmii_tx_data[2],
        xgmii_tx_control[1], xgmii_tx_data[1],
        xgmii_tx_control[0], xgmii_tx_data[0]
    };

    /// - External modules -------------------------------------------------------------------------

    // Ethernet PHY reset syncronizer
    reset_syncronizer phy_reset_syncronizer_i (
        .i_clock(clock),
        .i_async_reset_n(sfp_phy_ready),
        .o_sync_reset_n(phy_reset_n)
    );

    // XCVR 1G fPLL
    xcvr_1g_pll xcvr_1g_pll_i (
        .pll_refclk0(xcvr_1g_ref_clock),
        .pll_powerdown(xcvr_1g_pll_powerdown),
        .pll_locked(xcvr_1g_pll_locked),
        .pll_cal_busy(xcvr_1g_pll_cal_busy),
        .tx_serial_clk(xcvr_1g_tx_serial_clk)
    );

    // XCVR 10G ATX-PLL
    xcvr_10g_pll xcvr_10g_pll_i (
        .pll_refclk0(xcvr_10g_ref_clock),
        .pll_powerdown(xcvr_10g_pll_powerdown),
        .pll_locked(xcvr_10g_pll_locked),
        .pll_cal_busy(xcvr_10g_pll_cal_busy),
        .tx_serial_clk(xcvr_10g_tx_serial_clk)
    );

    // XCVR reset controller
    xcvr_reset_control xcvr_reset_control_i (
        .clock(clock),
        .reset(phy_reset),
        .pll_locked(xcvr_pll_locked),
        .pll_powerdown(xcvr_pll_powerdown),
        .pll_select(),
        .rx_analogreset(xcvr_rx_analogreset),
        .rx_cal_busy(xcvr_rx_cal_busy),
        .rx_digitalreset(xcvr_rx_digitalreset),
        .rx_is_lockedtodata(xcvr_rx_is_lockedtodata),
        .rx_ready(),
        .tx_analogreset(xcvr_tx_analogreset),
        .tx_cal_busy(xcvr_tx_cal_busy),
        .tx_digitalreset(xcvr_tx_digitalreset),
        .tx_ready()
    );

    // 1000Base-T/10GBase-T ethernet PHY
    ethernet_phy ethernet_phy_i (
        .tx_serial_clk_10g(xcvr_10g_tx_serial_clk),
        .tx_serial_clk_1g(xcvr_1g_tx_serial_clk),
        .rx_cdr_ref_clk_10g(xcvr_10g_ref_clock),
        .rx_cdr_ref_clk_1g(xcvr_1g_ref_clock),
        .xgmii_tx_clk(xgmii_clock),
        .xgmii_rx_clk(xgmii_clock),
        .tx_analogreset(xcvr_tx_analogreset),
        .tx_digitalreset(xcvr_tx_digitalreset),
        .rx_analogreset(xcvr_rx_analogreset),
        .rx_digitalreset(xcvr_rx_digitalreset),
        .usr_seq_reset(reset),
        .mgmt_clk(clock),
        .mgmt_clk_reset(reset),
        .mgmt_address(),
        .mgmt_read(),
        .mgmt_readdata(),
        .mgmt_waitrequest(),
        .mgmt_write(),
        .mgmt_writedata(),
        .gmii_tx_d(i_gmii_tx_d),
        .gmii_rx_d(o_gmii_rx_d),
        .gmii_tx_en(i_gmii_tx_en),
        .gmii_tx_err(i_gmii_tx_err),
        .gmii_rx_err(o_gmii_rx_err),
        .gmii_rx_dv(o_gmii_rx_dv),
        .led_an(),
        .led_char_err(),
        .led_disp_err(),
        .led_link(),
        .tx_pcfifo_error_1g(),
        .rx_pcfifo_error_1g(),
        .rx_syncstatus(),
        .rx_clkslip(),
        .xgmii_tx_dc(xgmii_tx_dc),
        .xgmii_rx_dc(xgmii_rx_dc),
        .rx_is_lockedtodata(xcvr_rx_is_lockedtodata),
        .tx_cal_busy(xcvr_tx_cal_busy),
        .rx_cal_busy(xcvr_rx_cal_busy),
        .rx_data_ready(),
        .rx_block_lock(),
        .rx_hi_ber(),
        .tx_serial_data(o_sfp_tx_serial_data),
        .rx_serial_data(i_sfp_rx_serial_data),
        .tx_clkout(o_gmii_clock)
    );

    // XGMII data clock
    xgmii_pll xgmii_pll_i (
        .pll_refclk0(xcvr_10g_ref_clock),
        .pll_powerdown(xgmii_pll_powerdown),
        .pll_locked(xgmii_pll_locked),
        .pll_cal_busy(xgmii_pll_cal_busy),
        .outclk0(xgmii_clock)
    );

    /// - Outputs ----------------------------------------------------------------------------------

    always_comb o_sfp_tx_disable = sfp_tx_disable;

    assign io_sfp_mod1_scl = sfp_mod1_scl;
    assign io_sfp_mod2_sda = sfp_mod2_sda;

    always_comb o_xgmii_clock = xgmii_clock;
    always_comb o_xgmii_rx_data = xgmii_rx_data;
    always_comb o_xgmii_rx_control = xgmii_rx_control;

endmodule


`endif // SFP_ETHERNET_PHY_CONTROL_SV_

