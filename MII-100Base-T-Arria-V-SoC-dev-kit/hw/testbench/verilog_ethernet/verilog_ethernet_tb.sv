/**
 *  File:               verilog_ethernet_tb.sv
 *  Modules:            verilog_ethernet_tb
 *  Start design:       31.03.2021
 *  Last revision:      31.03.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  Test Bench for "ethernet_on_arria_v_soc_dev_kit" module
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
 *      31.03.2021              Create first versions of modules: "verilog_ethernet_tb" - (Vadim A. Lukinov)
 *
 */
`ifndef HS_RECORDER_DATA_ROUTER_TB_SV_
`define HS_RECORDER_DATA_ROUTER_TB_SV_


/**
 *  module - "verilog_ethernet_tb"
 *  Test Bench for "ethernet_on_arria_v_soc_dev_kit" module
 *
 */
module verilog_ethernet_tb();

    timeunit 1ns;
    timeprecision 1ns;

    /// - Internal parameters & constants ----------------------------------------------------------

    localparam time TIME_MULTIPLICATOR = 1s;

    localparam time SYSTEM_CLOCK_FREQUENCY = 125000000;
    localparam time SYSTEM_HALF_CLOCK_DELAY = (TIME_MULTIPLICATOR / SYSTEM_CLOCK_FREQUENCY) / 2;
    localparam time SYSTEM_CLOCK_DELAY = SYSTEM_HALF_CLOCK_DELAY * 2;

    localparam time ETH_PHY_CLOCK_FREQUENCY = 25000000;
    localparam time ETH_PHY_HALF_CLOCK_DELAY = (TIME_MULTIPLICATOR / ETH_PHY_CLOCK_FREQUENCY) / 2;
    localparam time ETH_PHY_CLOCK_DELAY = ETH_PHY_HALF_CLOCK_DELAY * 2;

    /// - Internal logic ---------------------------------------------------------------------------

    bit clock;
    bit eth_phy_clock;

    logic phy_reset_n;

    bit[3 : 0] phy_rx_d;
    bit phy_rx_dv;
    bit phy_rx_er;

    bit[3 : 0] phy_tx_d;
    bit phy_tx_en;

    bit[3 : 0] arp_packet[] = '{
        4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'hD,
        4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'h8, 4'h0, 4'h0, 4'h0,
        4'h7, 4'h2, 4'h9, 4'hE, 4'hE, 4'h5, 4'h1, 4'h8, 4'h8, 4'h0, 4'h6, 4'h0, 4'h0, 4'h0, 4'h1, 4'h0,
        4'h8, 4'h0, 4'h0, 4'h0, 4'h6, 4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h1, 4'h0, 4'h8, 4'h0, 4'h0, 4'h0,
        4'h7, 4'h2, 4'h9, 4'hE, 4'hE, 4'h5, 4'h1, 4'h8, 4'h0, 4'hC, 4'h8, 4'hA, 4'h1, 4'h0, 4'hA, 4'h0,
        4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hC, 4'h8, 4'hA,
        4'h1, 4'h0, 4'h0, 4'h8, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
        4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
        4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h8, 4'hE, 4'h1, 4'hF, 4'hB, 4'h6, 4'h3, 4'hF
    };

    bit[3 : 0] icmp_windows_packet[] = '{
        4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'hD,
        4'h2, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'hD, 4'h7, 4'h3,
        4'h5, 4'h4, 4'h8, 4'hB, 4'hF, 4'h8, 4'hC, 4'hC, 4'h8, 4'h0, 4'h0, 4'h0, 4'h5, 4'h4, 4'h0, 4'h0,
        4'h0, 4'h0, 4'hC, 4'h3, 4'h1, 4'hE, 4'hA, 4'hD, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h8, 4'h1, 4'h0,
        4'h5, 4'hD, 4'h4, 4'h1, 4'h0, 4'hC, 4'h8, 4'hA, 4'h1, 4'h0, 4'h1, 4'h0, 4'h0, 4'hC, 4'h8, 4'hA,
        4'h1, 4'h0, 4'h0, 4'h8, 4'h8, 4'h0, 4'h0, 4'h0, 4'hC, 4'h4, 4'hC, 4'hF, 4'h0, 4'h0, 4'h1, 4'h0,
        4'h0, 4'h0, 4'hF, 4'h5, 4'h1, 4'h6, 4'h2, 4'h6, 4'h3, 4'h6, 4'h4, 4'h6, 4'h5, 4'h6, 4'h6, 4'h6,
        4'h7, 4'h6, 4'h8, 4'h6, 4'h9, 4'h6, 4'hA, 4'h6, 4'hB, 4'h6, 4'hC, 4'h6, 4'hD, 4'h6, 4'hE, 4'h6,
        4'hF, 4'h6, 4'h0, 4'h7, 4'h1, 4'h7, 4'h2, 4'h7, 4'h3, 4'h7, 4'h4, 4'h7, 4'h5, 4'h7, 4'h6, 4'h7,
        4'h7, 4'h7, 4'h1, 4'h6, 4'h2, 4'h6, 4'h3, 4'h6, 4'h4, 4'h6, 4'h5, 4'h6, 4'h6, 4'h6, 4'h7, 4'h6,
        4'h8, 4'h6, 4'h9, 4'h6, 4'hF, 4'h3, 4'hD, 4'h0, 4'h3, 4'hF, 4'h8, 4'h1
    };

    bit[3 : 0] icmp_linux_packet[] = '{
        4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'h5, 4'hD,
        4'h2, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h8, 4'h0, 4'h0, 4'h0,
        4'h7, 4'h2, 4'h9, 4'hE, 4'hE, 4'h5, 4'h1, 4'h8, 4'h8, 4'h0, 4'h0, 4'h0, 4'h5, 4'h4, 4'h0, 4'h0,
        4'h0, 4'h0, 4'h4, 4'h5, 4'h5, 4'h7, 4'hB, 4'hD, 4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h4, 4'h1, 4'h0,
        4'h0, 4'h4, 4'h3, 4'hF, 4'h0, 4'hC, 4'h8, 4'hA, 4'h1, 4'h0, 4'hA, 4'h0, 4'h0, 4'hC, 4'h8, 4'hA,
        4'h1, 4'h0, 4'h0, 4'h8, 4'h8, 4'h0, 4'h0, 4'h0, 4'hD, 4'h8, 4'hE, 4'h5, 4'h0, 4'h0, 4'h4, 4'h0,
        4'h0, 4'h0, 4'h1, 4'h0, 4'h7, 4'h0, 4'hD, 4'h9, 4'h4, 4'h7, 4'h0, 4'h6, 4'h0, 4'h0, 4'h0, 4'h0,
        4'h0, 4'h0, 4'h0, 4'h0, 4'h2, 4'h2, 4'hC, 4'hC, 4'hD, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0,
        4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h1, 4'h1, 4'h1, 4'h2, 4'h1, 4'h3, 4'h1, 4'h4, 4'h1, 4'h5, 4'h1,
        4'h6, 4'h1, 4'h7, 4'h1, 4'h8, 4'h1, 4'h9, 4'h1, 4'hA, 4'h1, 4'hB, 4'h1, 4'hC, 4'h1, 4'hD, 4'h1,
        4'hE, 4'h1, 4'hF, 4'h1, 4'h0, 4'h2, 4'h1, 4'h2, 4'h2, 4'h2, 4'h3, 4'h2, 4'h4, 4'h2, 4'h5, 4'h2,
        4'h6, 4'h2, 4'h7, 4'h2, 4'h8, 4'h2, 4'h9, 4'h2, 4'hA, 4'h2, 4'hB, 4'h2, 4'hC, 4'h2, 4'hD, 4'h2,
        4'hE, 4'h2, 4'hF, 4'h2, 4'h0, 4'h3, 4'h1, 4'h3, 4'h2, 4'h3, 4'h3, 4'h3, 4'h4, 4'h3, 4'h5, 4'h3,
        4'h6, 4'h3, 4'h7, 4'h3, 4'h5, 4'hE, 4'h5, 4'hF, 4'h5, 4'h0, 4'h6, 4'h1
    };

    /// - Logic description ------------------------------------------------------------------------

    // System Clock process
    initial forever #SYSTEM_HALF_CLOCK_DELAY clock = ~clock;
    initial forever #ETH_PHY_HALF_CLOCK_DELAY eth_phy_clock = ~eth_phy_clock;
    initial begin

        @(posedge eth_phy_clock);
        while (phy_reset_n) @(posedge eth_phy_clock);
        while (!phy_reset_n) @(posedge eth_phy_clock);
        repeat (8) @(posedge eth_phy_clock);

        // Sent ARP request
        repeat (3) begin
            phy_rx_dv = 1'b1;
            for (int i = 0; i < $size(arp_packet); ++i) begin
                phy_rx_d = arp_packet[i];
                @(posedge eth_phy_clock);
            end
            phy_rx_dv = 1'b0;
            phy_rx_d = 0;

            while (!phy_tx_en) @(posedge eth_phy_clock);
            while (phy_tx_en) @(posedge eth_phy_clock);
            repeat (32) @(posedge eth_phy_clock);
        end

        // Sent Windows ICMP request
        repeat (3) begin
            phy_rx_dv = 1'b1;
            for (int i = 0; i < $size(icmp_windows_packet); ++i) begin
                phy_rx_d = icmp_windows_packet[i];
                @(posedge eth_phy_clock);
            end
            phy_rx_dv = 1'b0;
            phy_rx_d = 0;

            while (!phy_tx_en) @(posedge eth_phy_clock);
            while (phy_tx_en) @(posedge eth_phy_clock);
            repeat (32) @(posedge eth_phy_clock);
        end

        // Sent Linux ICMP request
        repeat (3) begin
            phy_rx_dv = 1'b1;
            for (int i = 0; i < $size(icmp_linux_packet); ++i) begin
                phy_rx_d = icmp_linux_packet[i];
                @(posedge eth_phy_clock);
            end
            phy_rx_dv = 1'b0;
            phy_rx_d = 0;

            while (!phy_tx_en) @(posedge eth_phy_clock);
            while (phy_tx_en) @(posedge eth_phy_clock);
            repeat (32) @(posedge eth_phy_clock);
        end

    end

    /// - External modules -------------------------------------------------------------------------

    mii_100base_t_arria_v_soc_dev_kit #(
        .FPGA_RESET_DELAY_US(1)
    ) mii_100base_t_arria_v_soc_dev_kit_i (
        .i_ref_clock(clock),

        .o_phy_reset_n(phy_reset_n),
        .i_phy_port0_rx_clk(eth_phy_clock),
        .i_phy_port0_rx_d(phy_rx_d),
        .i_phy_port0_rx_dv(phy_rx_dv),
        .i_phy_port0_rx_er(phy_rx_er),
        .i_phy_port0_tx_clk(eth_phy_clock),
        .o_phy_port0_tx_d(phy_tx_d),
        .o_phy_port0_tx_en(phy_tx_en)
    );

endmodule


`endif // HS_RECORDER_DATA_ROUTER_TB_SV_

