/**
 *  File:               sfp_ethernet_phy_control.sv
 *  Modules:            sfp_ethernet_phy_control
 *  Start design:       10.02.2022
 *  Last revision:      10.02.2022
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  SFP+ USXGMII NBase-T ethernet PHY controller on Arria 10
 *  Intel Arria V (5ASTFD5K3F40I3) FPGA
 *  Copyright (c) 2022 Vadim A. Lukinov
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
 *  SFP+ USXGMII NBase-T ethernet PHY controller on Arria 10
 *
 */
module sfp_ethernet_phy_control
(
    input logic i_clock,
    input logic i_reset_n,

    input logic i_xcvr_ref_clock,

    input logic i_sfp_rx_serial_data,
    output logic o_sfp_tx_serial_data,

    input logic i_sfp_los,
    input logic i_sfp_tx_fault,
    input logic i_sfp_mod0_prsnt_n,
    output logic o_sfp_tx_disable,
    inout wire io_sfp_mod1_scl,
    inout wire io_sfp_mod2_sda,
    output logic[1 : 0] o_sfp_rate_sel,

    output logic o_xgmii_clock,
    output logic o_xgmii_reset_n,
    output logic o_xgmii_power_on_reset_n,

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

    logic xcvr_ref_clock;

    logic sfp_los;
    logic sfp_tx_fault;
    logic sfp_mod0_prsnt_n;
    logic sfp_tx_disable;

    wire sfp_mod1_scl = 1'bZ;
    wire sfp_mod2_sda = 1'bZ;

    logic sfp_phy_ready;

    logic phy_reset;
    logic phy_reset_n;

    logic xcvr_pll_locked;
    logic xcvr_pll_cal_busy;
    logic xcvr_pll_powerdown;
    logic xcvr_tx_serial_clk;

    logic xcvr_rx_cal_busy;
    logic xcvr_rx_analogreset;
    logic xcvr_rx_digitalreset;
    logic xcvr_rx_is_lockedtodata;

    logic xcvr_tx_cal_busy;
    logic xcvr_tx_analogreset;
    logic xcvr_tx_digitalreset;

    logic usxgmii_clock;
    logic xgmii_clock;
    logic xgmii_pll_locked;
    logic xgmii_pll_powerdown;
    logic xgmii_pll_cal_busy;

    logic xgmii_power_on_reset_n;
    logic xgmii_async_reset_n;
    logic xgmii_reset_n;

    logic usxgmii_rx_valid;
    logic[3 : 0] usxgmii_rx_control;
    logic[31 : 0] usxgmii_rx_data;

    logic usxgmii_tx_valid;
    logic[3 : 0] usxgmii_tx_control;
    logic[31 : 0] usxgmii_tx_data;

    /// - Logic description ------------------------------------------------------------------------

    always_comb clock = i_clock;
    always_comb reset = ~reset_n;
    always_comb reset_n = i_reset_n;

    always_comb xcvr_ref_clock = i_xcvr_ref_clock;

    always_comb sfp_los = i_sfp_los;
    always_comb sfp_tx_fault = i_sfp_tx_fault;
    always_comb sfp_mod0_prsnt_n = i_sfp_mod0_prsnt_n;
    always_comb sfp_tx_disable = 1'b0;

    always_comb sfp_phy_ready = ~(sfp_los | sfp_tx_fault | sfp_mod0_prsnt_n);
    always_comb phy_reset = ~phy_reset_n;

    always_comb xgmii_pll_powerdown = reset;

    always_comb xgmii_async_reset_n = sfp_phy_ready & xgmii_pll_locked;

    /// - External modules -------------------------------------------------------------------------

    // Ethernet PHY reset syncronizer
    reset_synchronizer phy_reset_synchronizer_i (
        .i_clock(clock),
        .i_async_reset_n(sfp_phy_ready),
        .o_sync_reset_n(phy_reset_n)
    );

    // XCVR ATX-PLL
    xcvr_pll xcvr_pll_i (
        .pll_cal_busy(xcvr_pll_cal_busy),
        .pll_locked(xcvr_pll_locked),
        .pll_powerdown(xcvr_pll_powerdown),
        .pll_refclk0(xcvr_ref_clock),
        .tx_serial_clk(xcvr_tx_serial_clk)
    );

    // XCVR reset controller
    xcvr_reset_control xcvr_reset_control_i (
        .clock(clock),
        .pll_locked(xcvr_pll_locked),
        .pll_powerdown(xcvr_pll_powerdown),
        .pll_select(),
        .reset(phy_reset),
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

    // USXGMII NBase-T ethernet PHY
    usxgmii_eth_phy usxgmii_eth_phy_i (
        .csr_readdata(),
        .csr_writedata(),
        .csr_address(),
        .csr_waitrequest(),
        .csr_read(),
        .csr_write(),
        .csr_clk(clock),

        .led_an(),
        .operating_speed(),

        .reconfig_write(),
        .reconfig_read(),
        .reconfig_address(),
        .reconfig_writedata(),
        .reconfig_readdata(),
        .reconfig_waitrequest(),
        .reconfig_clk(clock),
        .reconfig_reset(reset),

        .reset(phy_reset),

        .rx_analogreset(xcvr_rx_analogreset),
        .rx_block_lock(),
        .rx_cal_busy(xcvr_rx_cal_busy),
        .rx_cdr_refclk_1(xcvr_ref_clock),
        .rx_digitalreset(xcvr_rx_digitalreset),
        .rx_is_lockedtodata(xcvr_rx_is_lockedtodata),
        .rx_pma_clkout(),
        .rx_serial_data(i_sfp_rx_serial_data),

        .tx_analogreset(xcvr_tx_analogreset),
        .tx_cal_busy(xcvr_tx_cal_busy),
        .tx_digitalreset(xcvr_tx_digitalreset),
        .tx_serial_clk(xcvr_tx_serial_clk),
        .tx_serial_data(o_sfp_tx_serial_data),

        .xgmii_rx_control(usxgmii_rx_control),
        .xgmii_rx_coreclkin(usxgmii_clock),
        .xgmii_rx_data(usxgmii_rx_data),
        .xgmii_rx_valid(usxgmii_rx_valid),
        .xgmii_tx_control(usxgmii_tx_control),
        .xgmii_tx_coreclkin(usxgmii_clock),
        .xgmii_tx_data(usxgmii_tx_data),
        .xgmii_tx_valid(usxgmii_tx_valid)
    );

    // USXGMII core fPLL
    usxgmii_eth_pll usxgmii_eth_pll_i (
        .outclk0(xgmii_clock),      // 156.25 XGMII clock
        .outclk1(usxgmii_clock),    // 312.5 USXGMII core clock
        .pll_cal_busy(xgmii_pll_cal_busy),
        .pll_locked(xgmii_pll_locked),
        .pll_powerdown(xgmii_pll_powerdown),
        .pll_refclk0(xcvr_ref_clock)
    );

    // XGMII reset syncronizer
    reset_synchronizer xgmii_reset_synchronizer_i (
        .i_clock(xgmii_clock),
        .i_async_reset_n(xgmii_async_reset_n),
        .o_sync_reset_n(xgmii_reset_n)
    );

    // XGMII power-on-reset syncronizer
    reset_synchronizer xgmii_power_on_reset_synchronizer_i (
        .i_clock(xgmii_clock),
        .i_async_reset_n(xgmii_pll_locked),
        .o_sync_reset_n(xgmii_power_on_reset_n)
    );

    // USXGMII to XGMII protocol converter
    usxgmii_to_xgmii_convert usxgmii_to_xgmii_convert_i (
        .i_xgmii_clock(xgmii_clock),
        .i_xgmii_reset_n(xgmii_reset_n),
        .i_usxgmii_clock(usxgmii_clock),

        .i_usxgmii_valid(usxgmii_rx_valid),
        .i_usxgmii_control(usxgmii_rx_control),
        .i_usxgmii_data(usxgmii_rx_data),

        .o_xgmii_control(o_xgmii_rx_control),
        .o_xgmii_data(o_xgmii_rx_data)
    );

    // XGMII to USXGMII protocol converter
    xgmii_to_usxgmii_convert xgmii_to_usxgmii_convert_i (
        .i_xgmii_clock(xgmii_clock),
        .i_xgmii_reset_n(xgmii_reset_n),
        .i_usxgmii_clock(usxgmii_clock),

        .i_xgmii_control(i_xgmii_tx_control),
        .i_xgmii_data(i_xgmii_tx_data),

        .o_usxgmii_valid(usxgmii_tx_valid),
        .o_usxgmii_control(usxgmii_tx_control),
        .o_usxgmii_data(usxgmii_tx_data)
    );

    /// - Outputs ----------------------------------------------------------------------------------

    always_comb o_sfp_tx_disable = sfp_tx_disable;

    assign io_sfp_mod1_scl = sfp_mod1_scl;
    assign io_sfp_mod2_sda = sfp_mod2_sda;

    always_comb o_xgmii_clock = xgmii_clock;
    always_comb o_xgmii_reset_n = xgmii_reset_n;
    always_comb o_xgmii_power_on_reset_n = xgmii_power_on_reset_n;

endmodule


`endif // SFP_ETHERNET_PHY_CONTROL_SV_

