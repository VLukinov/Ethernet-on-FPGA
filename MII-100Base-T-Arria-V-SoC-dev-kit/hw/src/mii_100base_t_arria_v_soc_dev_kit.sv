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
(
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

    localparam FPGA_REFERENCE_CLOCK_FREQUENCY = 125000000;
    localparam FPGA_RESET_DELAY_MS = (FPGA_REFERENCE_CLOCK_FREQUENCY / 1000) * 1;
    localparam FPGA_RESET_COUNTER_MODULE =FPGA_RESET_DELAY_MS;
    localparam FPGA_RESET_COUNTER_WIDTH = $clog2(FPGA_RESET_COUNTER_MODULE);

    /// - Internal logic ---------------------------------------------------------------------------

    logic ref_clock;

    bit reset;
    bit reset_counter_en;
    bit[FPGA_RESET_COUNTER_WIDTH - 1 : 0] reset_counter;

    /// - Logic description ------------------------------------------------------------------------

    always_comb ref_clock = i_ref_clock;

    always_ff @(posedge ref_clock) reset <= reset_counter_en;

    always_comb reset_counter_en = reset_counter != FPGA_RESET_COUNTER_MODULE - 1;
    always_ff @(posedge ref_clock) begin
        if (reset_counter_en)
            reset_counter <= reset_counter + 1'b1;
    end

    /// - External modules -------------------------------------------------------------------------

    fpga_core #(
        .TARGET("ALTERA")
    ) fpga_core_i (
        // Clock: 25MHz
        .clk(ref_clock),
        // Synchronous reset
        .rst(reset),

        // GPIO
        .btn(),
        .sw(),
        .led0_r(),
        .led0_g(),
        .led0_b(),
        .led1_r(),
        .led1_g(),
        .led1_b(),
        .led2_r(),
        .led2_g(),
        .led2_b(),
        .led3_r(),
        .led3_g(),
        .led3_b(),
        .led4(),
        .led5(),
        .led6(),
        .led7(),

        // Ethernet: 100BASE-T MII (no GMII gtx_clk & no CRS, COL)
        .phy_rx_clk(i_phy_port0_rx_clk),
        .phy_rxd(i_phy_port0_rx_d),
        .phy_rx_dv(i_phy_port0_rx_dv),
        .phy_rx_er(i_phy_port0_rx_er),
        .phy_tx_clk(i_phy_port0_tx_clk),
        .phy_txd(o_phy_port0_tx_d),
        .phy_tx_en(o_phy_port0_tx_en),
        .phy_tx_er(o_phy_port0_tx_er),
        .phy_col(),
        .phy_crs(),
        .phy_reset_n(o_phy_reset_n),

        // UART: 115200 bps, 8N1
        .uart_rxd(),
        .uart_txd()
    );

    /// - Outputs ----------------------------------------------------------------------------------



endmodule


`endif // MII_100BASE_T_ARRIA_V_SOC_DEV_KIT_SV_

