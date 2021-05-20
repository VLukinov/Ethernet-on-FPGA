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


import verilog_ethernet_pack::*;


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

    localparam ETH_PHY_RX_TIMEOUT_TICKS = 100;

    localparam mac_address_t LOCAL_MAC_ADDRESS = { 8'h08, 8'h00, 8'h27, 8'hE9, 8'h5E, 8'h81 };
    localparam ip_address_t LOCAL_IP_ADDRESS = { 8'd192, 8'd168, 8'd1, 8'd10 };

    localparam octet_t[1 : 0] UDP_SRC_PORT = 43150;
    localparam octet_t[1 : 0] UDP_DST_PORT = 1234;

    /// - Internal logic ---------------------------------------------------------------------------

    bit clock;
    bit eth_phy_clock;

    logic phy_reset_n;

    bit[3 : 0] phy_rx_d;
    bit phy_rx_dv;
    bit phy_rx_er;

    bit[3 : 0] phy_tx_d;
    bit phy_tx_en;

    octet_t arp_packet[] = '{
        8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'hD5,
        8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h08, 8'h00,
        8'h27, 8'hE9, 8'h5E, 8'h81, 8'h08, 8'h06, 8'h00, 8'h01,
        8'h08, 8'h00, 8'h06, 8'h04, 8'h00, 8'h01, 8'h08, 8'h00,
        8'h27, 8'hE9, 8'h5E, 8'h81, 8'hC0, 8'hA8, 8'h01, 8'h0A,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hC0, 8'hA8,
        8'h01, 8'h80, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h00, 8'h00, 8'hE8, 8'hF1, 8'h6B, 8'hF3
    };

    octet_t udp_packet[] = '{
        8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'hD5,
        8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h08, 8'h00,
        8'h27, 8'hE9, 8'h5E, 8'h81, 8'h08, 8'h00, 8'h45, 8'h00,
        8'h00, 8'h2B, 8'h12, 8'h67, 8'h40, 8'h00, 8'h40, 8'h11,
        8'hA4, 8'h80, 8'hC0, 8'hA8, 8'h01, 8'h0A, 8'hC0, 8'hA8,
        8'h01, 8'h80, 8'hA8, 8'h8E, 8'h04, 8'hD2, 8'h00, 8'h17,
        8'h8D, 8'h6C, 8'h48, 8'h65, 8'h6C, 8'h6C, 8'h6F, 8'h20,
        8'h57, 8'h6F, 8'h72, 8'h64, 8'h20, 8'h29, 8'h29, 8'h29,
        8'h0A, 8'h00, 8'h00, 8'h00, 8'hC2, 8'h22, 8'h06, 8'h87
    };

    octet_t icmp_windows_packet[] = '{
        8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'hD5,
        8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'hD0, 8'h37,
        8'h45, 8'hB8, 8'h8F, 8'hCC, 8'h08, 8'h00, 8'h45, 8'h00,
        8'h00, 8'h3C, 8'hE1, 8'hDA, 8'h00, 8'h00, 8'h80, 8'h01,
        8'hD5, 8'h14, 8'hC0, 8'hA8, 8'h01, 8'h01, 8'hC0, 8'hA8,
        8'h01, 8'h80, 8'h08, 8'h00, 8'h4C, 8'hFC, 8'h00, 8'h01,
        8'h00, 8'h5F, 8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66,
        8'h67, 8'h68, 8'h69, 8'h6A, 8'h6B, 8'h6C, 8'h6D, 8'h6E,
        8'h6F, 8'h70, 8'h71, 8'h72, 8'h73, 8'h74, 8'h75, 8'h76,
        8'h77, 8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66, 8'h67,
        8'h68, 8'h69, 8'h3F, 8'h0D, 8'hF3, 8'h18
    };

    octet_t icmp_linux_packet[] = '{
        8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'h55, 8'hD5,
        8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h08, 8'h00,
        8'h27, 8'hE9, 8'h5E, 8'h81, 8'h08, 8'h00, 8'h45, 8'h00,
        8'h00, 8'h54, 8'h75, 8'hDB, 8'h40, 8'h00, 8'h40, 8'h01,
        8'h40, 8'hF3, 8'hC0, 8'hA8, 8'h01, 8'h0A, 8'hC0, 8'hA8,
        8'h01, 8'h80, 8'h08, 8'h00, 8'h8D, 8'h5E, 8'h00, 8'h04,
        8'h00, 8'h01, 8'h07, 8'h9D, 8'h74, 8'h60, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h22, 8'hCC, 8'h0D, 8'h00, 8'h00, 8'h00,
        8'h00, 8'h00, 8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15,
        8'h16, 8'h17, 8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D,
        8'h1E, 8'h1F, 8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25,
        8'h26, 8'h27, 8'h28, 8'h29, 8'h2A, 8'h2B, 8'h2C, 8'h2D,
        8'h2E, 8'h2F, 8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35,
        8'h36, 8'h37, 8'hE5, 8'hF5, 8'h05, 8'h16
    };

    mac_address_t src_mac_address = LOCAL_MAC_ADDRESS;
    mac_address_t src_ip_address = LOCAL_IP_ADDRESS;
    octet_t[1 : 0] udp_src_port = UDP_SRC_PORT;

    mac_address_t dst_mac_address = { 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF };   // For ARP packet MAC address
    mac_address_t dst_ip_address = mii_100base_t_arria_v_soc_dev_kit_i.LOCAL_IP;
    octet_t[1 : 0] udp_dst_port = UDP_DST_PORT;

    octet_t[1 : 0] packet_id;

    octet_t ethernet_frame[$];
    octet_t temp[$];

    frame_type_t frame_type;

    /// - Tsks && functions ------------------------------------------------------------------------

    task mii_phy_tx;
        input nibble_t[1 : 0] i_data[];

        @(posedge eth_phy_clock);
        phy_rx_dv = 1'b1;
        foreach (i_data[i]) begin
            for (int j = 0; j < 2; ++j) begin
                phy_rx_d = i_data[i][j];
                @(posedge eth_phy_clock);
            end
        end
        phy_rx_dv = 1'b0;
        phy_rx_d = 0;

    endtask

    task mii_phy_rx;
        output nibble_t[1 : 0] o_data[$];

        int counter;
        nibble_t[1 : 0] data;

        counter = 0;
        while (!phy_tx_en) @(posedge eth_phy_clock) begin
            if (++counter > ETH_PHY_RX_TIMEOUT_TICKS) begin
                $display("MII PHY Rx timeout...");
                break;
            end
        end

        counter = 0;
        o_data = {};
        while (phy_tx_en) begin
            repeat (2) begin
                data = { phy_tx_d, data[1] };
                @(posedge eth_phy_clock);
            end
            o_data.push_back(data);
        end
    endtask

    /// - Logic description ------------------------------------------------------------------------

    // System Clock process
    initial forever #SYSTEM_HALF_CLOCK_DELAY clock = ~clock;
    initial forever #ETH_PHY_HALF_CLOCK_DELAY eth_phy_clock = ~eth_phy_clock;

    // MII PHY clock process
    initial begin
        @(posedge eth_phy_clock);
        while (phy_reset_n) @(posedge eth_phy_clock);
        while (!phy_reset_n) @(posedge eth_phy_clock);
        repeat (8) @(posedge eth_phy_clock);

        // Create ethernet frame for ARP request
        arp_request_create(ethernet_frame, src_mac_address, src_ip_address, dst_ip_address);
        ethernet_frame_create(ethernet_frame, dst_mac_address, src_mac_address, ETHERNET_FRAME_TYPE_ARP);

        mii_phy_tx(ethernet_frame); // Send Ethernet frame (ARP request)
        mii_phy_rx(ethernet_frame); // Receive Ethernet frame (ARP reply)

        frame_type = ethernet_frame_parse(ethernet_frame);
        $display("Receive ethernet frame type: %04X", frame_type);

        if (frame_type == ETHERNET_FRAME_TYPE_ARP) begin
            dst_mac_address = arp_reply_parse(ethernet_frame);
        end

        // Copy UDP payload to ethernet frame buffer
        temp = udp_packet;
        ethernet_frame = temp[ETHERNET_FRAME_HEADER_SIZE + ETHERNET_IP4_PACKET_HEADER_SIZE + ETHERNET_UDP_PACKET_HEADER_SIZE : $ - (4 + 3)];
        $display("");

        // Create ethernet frame for UDP packet
        udp_packet_create(ethernet_frame, udp_src_port, udp_dst_port, src_ip_address, dst_ip_address);
        ip_packet_create(ethernet_frame, 16'h1267, ETHERNET_IP_UDP_ID, src_ip_address, dst_ip_address);
        ethernet_frame_create(ethernet_frame, dst_mac_address, src_mac_address, ETHERNET_FRAME_TYPE_IP4);

        mii_phy_tx(ethernet_frame); // Send Ethernet frame - UDP
        mii_phy_rx(ethernet_frame); // Receive Ethernet frame - UDP

        frame_type = ethernet_frame_parse(ethernet_frame);
        $display("Receive ethernet frame type: %04X", frame_type);

/*
        // Send Windows ICMP request - ping
        repeat (3) begin
            @(posedge eth_phy_clock) mii_phy_tx(icmp_windows_packet, $size(icmp_windows_packet));

            while (!phy_tx_en) @(posedge eth_phy_clock);
            while (phy_tx_en) @(posedge eth_phy_clock);
            repeat (32) @(posedge eth_phy_clock);
        end

        // Send Linux ICMP request - ping
        repeat (3) begin
            @(posedge eth_phy_clock) mii_phy_tx(icmp_linux_packet, $size(icmp_linux_packet));

            while (!phy_tx_en) @(posedge eth_phy_clock);
            while (phy_tx_en) @(posedge eth_phy_clock);
            repeat (32) @(posedge eth_phy_clock);
        end
*/

        repeat (128) @(posedge eth_phy_clock);
        $display("");
        $stop();

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

