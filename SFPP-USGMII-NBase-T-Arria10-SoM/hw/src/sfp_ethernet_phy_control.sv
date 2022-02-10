/**
 *  File:               sfp_ethernet_phy_control.sv
 *  Modules:            sfp_ethernet_phy_control
 *  Start design:       21.07.2021
 *  Last revision:      21.07.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  SFP+ USXGMII NBase-T ethernet PHY controller on Arria 10
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

    /// - External modules -------------------------------------------------------------------------


    /// - Outputs ----------------------------------------------------------------------------------

    always_comb o_sfp_tx_disable = sfp_tx_disable;

    assign io_sfp_mod1_scl = sfp_mod1_scl;
    assign io_sfp_mod2_sda = sfp_mod2_sda;

endmodule


`endif // SFP_ETHERNET_PHY_CONTROL_SV_

