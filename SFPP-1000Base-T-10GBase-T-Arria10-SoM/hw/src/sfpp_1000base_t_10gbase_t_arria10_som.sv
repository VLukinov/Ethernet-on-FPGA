/**
 *  File:               sfpp_1000base_t_10gbase_t_arria10_som.sv
 *  Modules:            sfpp_1000base_t_10gbase_t_arria10_som
 *  Start design:       20.07.2021
 *  Last revision:      20.07.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  SFP+ 1000Base-T/10GBase-T example of using the "verilog-ethernet" library on Arria 10 SoM
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
 *      20.07.2021              Create first versions of modules: "sfpp_1000base_t_10gbase_t_arria10_som" - (Vadim A. Lukinov)
 *
 */
`ifndef SFPP_1000BASE_T_10GBASE_T_ARRIA10_SOM_SV_
`define SFPP_1000BASE_T_10GBASE_T_ARRIA10_SOM_SV_


/**
 *  module - "sfpp_1000base_t_10gbase_t_arria10_som"
 *  SFP+ 1000Base-T/10GBase-T example of using the "verilog-ethernet" library on Arria 10 SoM
 *
 */
module sfpp_1000base_t_10gbase_t_arria10_som
#(
    parameter FPGA_REFERENCE_CLOCK_FREQUENCY = 125000000,
    parameter FPGA_RESET_DELAY_US = 20000,
    parameter FPGA_RESET_DELAY_TICKS = (FPGA_REFERENCE_CLOCK_FREQUENCY / 1000000) * FPGA_RESET_DELAY_US
)(
    input logic i_ref_clock,                                                                        // 125 Mhz
    input logic i_xcvr_ref_clock,                                                                   // 644.53125 MHz

    input logic i_sfp_rx_serial_data,
    output logic o_sfp_tx_serial_data,

    input logic i_sfp_los,
    input logic i_sfp_tx_fault,
    input logic i_sfp_mod0_prsnt_n,
    output logic o_sfp_tx_disable,
    inout wire io_sfp_mod1_scl,
    inout wire io_sfp_mod2_sda,
    output logic[1 : 0] o_sfp_rate_sel
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
    logic reset_n;

    bit[47 : 0] local_mac;
    bit[31 : 0] local_ip;
    bit[31 : 0] gateway_ip;
    bit[31 : 0] subnet_mask;
    bit[15 : 0] udp_dest_port;

    logic gmii_clock;
    logic gmii_reset_n;
    logic gmii_reset;

    logic gmii_clk_en;
    logic[7 : 0] gmii_rxd;
    logic gmii_rx_dv;
    logic gmii_rx_er;
    logic[7 : 0] gmii_txd;
    logic gmii_tx_en;
    logic gmii_tx_er;

    logic xgmii_clock;
    logic xgmii_reset_n;
    logic xgmii_reset;

    logic[63 : 0] xgmii_rx_data;
    logic[7 : 0] xgmii_rx_control;
    logic[63 : 0] xgmii_tx_data;
    logic[7 : 0] xgmii_tx_control;

    /// - Logic description ------------------------------------------------------------------------

    always_comb clock = ref_clock;
    always_comb ref_clock = i_ref_clock;

    always_ff @(posedge clock) reset_n <= ~reset;
    always_ff @(posedge clock) reset <= reset_counter_en;

    always_comb reset_counter_en = reset_counter != FPGA_RESET_COUNTER_MODULE - 1;
    always_ff @(posedge clock) begin
        if (reset_counter_en)
            reset_counter <= reset_counter + 1'b1;
    end

    always_comb local_mac = LOCAL_MAC;
    always_comb local_ip = LOCAL_IP;
    always_comb gateway_ip = GATEWAY_IP;
    always_comb subnet_mask = SUBNET_MASK;
    always_comb udp_dest_port = UDP_DEST_PORT;

    always_comb gmii_clk_en = 1'b1;

    always_ff @(posedge gmii_clock) gmii_reset <= ~gmii_reset_n;
    always_ff @(posedge gmii_clock) xgmii_reset <= ~xgmii_reset_n;

    /// - External modules -------------------------------------------------------------------------

    // SFP && 1000Base-T/10GBase-T ethernet PHY controller
    sfp_ethernet_phy_control sfp_ethernet_phy_control_i (
        .i_clock(clock),
        .i_reset_n(reset_n),

        .i_xcvr_1g_ref_clock(ref_clock),
        .i_xcvr_10g_ref_clock(i_xcvr_ref_clock),

        .i_sfp_rx_serial_data(i_sfp_rx_serial_data),
        .o_sfp_tx_serial_data(o_sfp_tx_serial_data),

        .i_sfp_los(i_sfp_los),
        .i_sfp_tx_fault(i_sfp_tx_fault),
        .i_sfp_mod0_prsnt_n(i_sfp_mod0_prsnt_n),
        .o_sfp_tx_disable(o_sfp_tx_disable),
        .io_sfp_mod1_scl(io_sfp_mod1_scl),
        .io_sfp_mod2_sda(io_sfp_mod2_sda),
        .o_sfp_rate_sel(o_sfp_rate_sel),

        .o_gmii_clock(gmii_clock),
        .o_gmii_rx_dv(gmii_rx_dv),
        .o_gmii_rx_err(gmii_rx_er),
        .o_gmii_rx_d(gmii_rxd),
        .i_gmii_tx_en(gmii_tx_en),
        .i_gmii_tx_err(gmii_tx_er),
        .i_gmii_tx_d(gmii_txd),

        .o_xgmii_clock(xgmii_clock),
        .o_xgmii_rx_data(xgmii_rx_data),
        .o_xgmii_rx_control(xgmii_rx_control),
        .i_xgmii_tx_data(xgmii_tx_data),
        .i_xgmii_tx_control(xgmii_tx_control)
    );

    // GMII reset syncronizer
    reset_syncronizer gmii_reset_syncronizer_i (
        .i_clock(gmii_clock),
        .i_async_reset_n(reset_n),
        .o_sync_reset_n(gmii_reset_n)
    );

    // UDP FPGA core
    gmii_fpga_core gmii_fpga_core_i (
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
        .phy_gmii_clk(gmii_clock),
        .phy_gmii_rst(gmii_reset),
        .phy_gmii_clk_en(gmii_clk_en),
        .phy_gmii_rxd(gmii_rxd),
        .phy_gmii_rx_dv(gmii_rx_dv),
        .phy_gmii_rx_er(gmii_rx_er),
        .phy_gmii_txd(gmii_txd),
        .phy_gmii_tx_en(gmii_tx_en),
        .phy_gmii_tx_er(gmii_tx_er),
        .phy_reset_n(),
        .phy_int_n()
    );

    // XGMII reset syncronizer
    reset_syncronizer xgmii_reset_syncronizer_i (
        .i_clock(xgmii_clock),
        .i_async_reset_n(reset_n),
        .o_sync_reset_n(xgmii_reset_n)
    );

    // 10G UDP FPGA core
    xgmii_fpga_core xgmii_fpga_core_i (
        // Clock: 156.25MHz
        .clk(xgmii_clock),
        // Synchronous reset
        .rst(xgmii_reset),

        // Ethernet configuration parameters
        .local_mac(local_mac),
        .local_ip(local_ip),
        .gateway_ip(gateway_ip),
        .subnet_mask(subnet_mask),
        .udp_dest_port(udp_dest_port),

        // Ethernet PHY: 10GBASE-T XGMII
        .sfp_txd(xgmii_tx_data),
        .sfp_txc(xgmii_tx_control),
        .sfp_rxd(xgmii_rx_data),
        .sfp_rxc(xgmii_rx_control)
    );

    /// - Outputs ----------------------------------------------------------------------------------



endmodule


`endif // SFPP_1000BASE_T_10GBASE_T_ARRIA10_SOM_SV_

