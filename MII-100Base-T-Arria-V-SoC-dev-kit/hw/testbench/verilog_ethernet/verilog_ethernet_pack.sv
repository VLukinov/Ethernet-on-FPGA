/**
 *  File:               verilog_ethernet_pack.sv
 *  Package:            verilog_ethernet_pack
 *  Start design:       6.05.2021
 *  Last revision:      12.05.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  Package for verilog-ethernet functions
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
 *      6.05.2021               Create first versions of package: "verilog_ethernet_pack" - (Vadim A. Lukinov)
 *      12.05.2021              Implement "ethernet_frame_create" && "arp_request_create" functions - (Vadim A. Lukinov)
 *
 */
`ifndef VERILOG_ETHERNET_PACK_SV_
`define VERILOG_ETHERNET_PACK_SV_


package verilog_ethernet_pack;

    typedef bit[7 : 0] octet_t;
    typedef bit[3 : 0] nibble_t;
    typedef octet_t[5 : 0] mac_address_t;
    typedef octet_t[1 : 0] frame_type_t;
    typedef octet_t[3 : 0] ip_address_t;

    // Ethernet frame header
    localparam ETHERNET_PREAMBLE_OCTETS = 7;
    typedef struct packed {
        frame_type_t frame_type;                                    // Ethernet frame type (IPv4 - 0x0800, ARP - 0x0806)
        mac_address_t src_mac_address;                              // MAC source
        mac_address_t dst_mac_address;                              // MAC destination
        octet_t sfd;                                                // Start frame delimiter (SFD) - 0xD5
        octet_t[ETHERNET_PREAMBLE_OCTETS - 1 : 0] preamble;         // Preamble - 0x55, 7 octets
    } ethernet_frame_header_t;
    localparam ETHERNET_FRAME_HEADER_SIZE = ($bits(ethernet_frame_header_t) / $bits(octet_t));

    // Ethernet ARP packet
    typedef struct packed {
        ip_address_t dst_ip_address;                                // Target protocol address (TPA)
        mac_address_t dst_mac_address;                              // Target hardware address (THA)
        ip_address_t src_ip_address;                                // Sender protocol address (SPA)
        mac_address_t src_mac_address;                              // Sender hardware address (SHA)
        octet_t[1 : 0] operation;                                   // Operation (OPER) - Specifies the operation that the sender is performing: 1 for request, 2 for reply
        octet_t p_len;                                              // Protocol address length (PLEN) - Length (in octets) of internetwork addresses. IPv4 address length is 4.
        octet_t h_len;                                              // Hardware address length (HLEN) - Length (in octets) of a hardware address. Ethernet address length is 6.
        octet_t[1 : 0] p_type;                                      // Protocol type (PTYPE)
        octet_t[1 : 0] h_type;                                      // Hardware type (HTYPE) - network link protocol type (Ethernet - 0x0001)
    } ethernet_arp_packet_t;
    localparam ETHERNET_ARP_PACKET_SIZE = ($bits(ethernet_arp_packet_t) / $bits(octet_t));

    typedef enum {
        ARP_REQUEST = 1, ARP_REPLY
    } arp_operation_t;

    // Ethernet IPv4 packet header
    typedef struct packed {
        // options Options (if IHL > 5)
        ip_address_t dst_ip_address;                                // Destination IP address
        ip_address_t src_ip_address;                                // Source IP address
        octet_t[1 : 0] header_checksum;                             // IPv4 header checksum
        octet_t protocol;                                           // Protocol type, or Protocol ID
        octet_t ttl;                                                // Time To Live (TTL)
        bit[12 : 0] fragment_offset;                                // Fragment Offset
        bit[2 : 0] flags;                                           // Packet fragmentation flags
        octet_t[1 : 0] identification;                              // Packet ID.
        octet_t[1 : 0] length;                                      // Total Length. This 16-bit field defines the entire packet size in bytes, including header and data.
        octet_t tos;                                                // Type of Service (ToS) -  (DSCP) + (ECN)
        nibble_t ihl;                                               // IPv4 header size (length). The minimum value for this field is 5 (5 × 32 bits = 160 bits = 20 bytes)
        nibble_t version;                                           // Version field. For IPv4, this is always equal to 0x4
    } ethernet_ip4_packet_header_t;
    localparam ETHERNET_IP4_PACKET_HEADER_SIZE = ($bits(ethernet_ip4_packet_header_t) / $bits(octet_t));

    localparam ETHERNET_FRAME_MIN_PAYLOAD_SIZE = 46;
    localparam ETHERNET_IP4_PACKET_MIN_SIZE = ETHERNET_IP4_PACKET_HEADER_SIZE;

    const octet_t ETHERNET_PREAMBLE = 8'h55;                        // Ethernet frame preamble - 7 octets (0x55)
    const octet_t ETHERNET_SFD = 8'hD5;                             // Ethernet frame "Start frame delimiter" (SFD)

    const octet_t[1 : 0] ETHERNET_TYPE_IP4 = 16'h0800;              // Internet protocol v4
    const octet_t[1 : 0] ETHERNET_TYPE_ARP = 16'h0806;              // Address resolution protocol (ARP)
    const octet_t[1 : 0] ETHERNET_LINK_PROTOCOL_TYPE = 16'h0001;    // Ethernet link protocol type for ARP HTYPE

    const nibble_t ETHERNET_IP_VERSION = 4'h4;                      // Ethernet IP packet version
    const nibble_t ETHERNET_IP_IHL = ETHERNET_IP4_PACKET_MIN_SIZE * $bits(octet_t) / 32;
    const octet_t ETHERNET_IP_TOS = 8'h00;
    const bit[2 : 0] ETHERNET_IP_FLAGS = 3'b010;
    const bit[12 : 0] ETHERNET_IP_FRAGMENT_OFFSET = 13'h00;
    const octet_t ETHERNET_IP_TTL = 64;

    const octet_t ETHERNET_IP_ICMP_ID = 8'h01;
    const octet_t ETHERNET_IP_TCP_ID = 8'h06;
    const octet_t ETHERNET_IP_UDP_ID = 8'h11;

    /**
     *  function - "print_buf"
     *  Prints the contents of the buffer / array in hexadecimal
     *
     *  Parameters:
     *      data - printed data array
     *
     */
    function print_buf(input bit[7 : 0] data[], input int columns = 32);
        int column;
        column = 0;
        foreach (data[i]) begin
            $write(" %02X", data[i]);
            if (++column == columns) begin
                $display("");
                column = 0;
            end
        end
        if (column != columns) begin
            $display("");
        end
    endfunction


    /**
     *  function - "print_mac_address"
     *  Prints MAC address
     *
     *  Parameters:
     *      address - printed MAC address
     *
     */
    function print_mac_address(input mac_address_t address);
        for (int i = 5; i >= 0; --i) begin
            $write("%02X", address[i]);
            if (i > 0) begin
                $write(":");
            end
        end
        $display();
    endfunction


    /**
     *  function - "print_mac_address"
     *  Prints IPv4 address
     *
     *  Parameters:
     *      address - printed IPv4 address
     *
     */
    function print_ip_address(input ip_address_t address);
        for (int i = 3; i >= 0; --i) begin
            $write("%d", address[i]);
            if (i > 0) begin
                $write(".");
            end
        end
        $display();
    endfunction


    /**
     *  function - "bit_revers_8"
     *  8-bit reversing bits
     *
     *  Return value:
     *      8-bit reversed word
     *
     *  Parameters:
     *      data_in - 8-bit reversing word
     *
     */
    function bit[7 : 0] bit_revers_8(input bit[7 : 0] data_in);
        for (int i = 0; i < $bits(data_in); ++i) begin
            bit_revers_8[i] = data_in[($bits(data_in) - 1) - i];
        end
    endfunction


    /**
     *  function - "bit_revers_16"
     *  16-bit reversing bits
     *
     *  Return value:
     *      16-bit reversed word
     *
     *  Parameters:
     *      data_in - 16-bit reversing word
     *
     */
    function bit[15 : 0] bit_revers_16(input bit[15 : 0] data_in);
        for (int i = 0; i < $bits(data_in); ++i) begin
            bit_revers_16[i] = data_in[($bits(data_in) - 1) - i];
        end
    endfunction


    /**
     *  function - "bit_revers_32"
     *  32-bit reversing bits
     *
     *  Return value:
     *      32-bit reversed word
     *
     *  Parameters:
     *      data_in - 32-bit reversing word
     *
     */
    function bit[31 : 0] bit_revers_32(input bit[31 : 0] data_in);
        for (int i = 0; i < $bits(data_in); ++i) begin
            bit_revers_32[i] = data_in[($bits(data_in) - 1) - i];
        end
    endfunction


    /**
     *  function - "ethernet_fcs"
     *  Calculates the Ethernet Frame check sequence (FCS - IEEE 802.3 32-bit CRC)
     *
     *  Return value:
     *      FCS - 32-bit CRC
     *
     *  Parameters:
     *      data_in_frame - input frame array
     *
     */
    function bit[31 : 0] ethernet_fcs(input octet_t data_in_frame[]);
        octet_t data_in;
        bit[31 : 0] lfsr_c, lfsr_q;

        lfsr_q = 32'hFFFFFFFF;
        foreach (data_in_frame[i]) begin
            data_in = bit_revers_8(data_in_frame[i]);
            begin
                lfsr_c[0] = lfsr_q[24] ^ lfsr_q[30] ^ data_in[0] ^ data_in[6];
                lfsr_c[1] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[6] ^ data_in[7];
                lfsr_c[2] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[6] ^ data_in[7];
                lfsr_c[3] = lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[7];
                lfsr_c[4] = lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6];
                lfsr_c[5] = lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
                lfsr_c[6] = lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7];
                lfsr_c[7] = lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[7];
                lfsr_c[8] = lfsr_q[0] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4];
                lfsr_c[9] = lfsr_q[1] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5];
                lfsr_c[10] = lfsr_q[2] ^ lfsr_q[24] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5];
                lfsr_c[11] = lfsr_q[3] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[27] ^ lfsr_q[28] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4];
                lfsr_c[12] = lfsr_q[4] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[4] ^ data_in[5] ^ data_in[6];
                lfsr_c[13] = lfsr_q[5] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[29] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[7];
                lfsr_c[14] = lfsr_q[6] ^ lfsr_q[26] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[7];
                lfsr_c[15] = lfsr_q[7] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[7];
                lfsr_c[16] = lfsr_q[8] ^ lfsr_q[24] ^ lfsr_q[28] ^ lfsr_q[29] ^ data_in[0] ^ data_in[4] ^ data_in[5];
                lfsr_c[17] = lfsr_q[9] ^ lfsr_q[25] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[1] ^ data_in[5] ^ data_in[6];
                lfsr_c[18] = lfsr_q[10] ^ lfsr_q[26] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[2] ^ data_in[6] ^ data_in[7];
                lfsr_c[19] = lfsr_q[11] ^ lfsr_q[27] ^ lfsr_q[31] ^ data_in[3] ^ data_in[7];
                lfsr_c[20] = lfsr_q[12] ^ lfsr_q[28] ^ data_in[4];
                lfsr_c[21] = lfsr_q[13] ^ lfsr_q[29] ^ data_in[5];
                lfsr_c[22] = lfsr_q[14] ^ lfsr_q[24] ^ data_in[0];
                lfsr_c[23] = lfsr_q[15] ^ lfsr_q[24] ^ lfsr_q[25] ^ lfsr_q[30] ^ data_in[0] ^ data_in[1] ^ data_in[6];
                lfsr_c[24] = lfsr_q[16] ^ lfsr_q[25] ^ lfsr_q[26] ^ lfsr_q[31] ^ data_in[1] ^ data_in[2] ^ data_in[7];
                lfsr_c[25] = lfsr_q[17] ^ lfsr_q[26] ^ lfsr_q[27] ^ data_in[2] ^ data_in[3];
                lfsr_c[26] = lfsr_q[18] ^ lfsr_q[24] ^ lfsr_q[27] ^ lfsr_q[28] ^ lfsr_q[30] ^ data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6];
                lfsr_c[27] = lfsr_q[19] ^ lfsr_q[25] ^ lfsr_q[28] ^ lfsr_q[29] ^ lfsr_q[31] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[7];
                lfsr_c[28] = lfsr_q[20] ^ lfsr_q[26] ^ lfsr_q[29] ^ lfsr_q[30] ^ data_in[2] ^ data_in[5] ^ data_in[6];
                lfsr_c[29] = lfsr_q[21] ^ lfsr_q[27] ^ lfsr_q[30] ^ lfsr_q[31] ^ data_in[3] ^ data_in[6] ^ data_in[7];
                lfsr_c[30] = lfsr_q[22] ^ lfsr_q[28] ^ lfsr_q[31] ^ data_in[4] ^ data_in[7];
                lfsr_c[31] = lfsr_q[23] ^ lfsr_q[29] ^ data_in[5];
            end
            lfsr_q = lfsr_c;
        end
        ethernet_fcs = ~bit_revers_32(lfsr_q);
    endfunction


    /**
     *  function - "ethernet_frame_create"
     *  Create ethernet frame - add ethernet frame header && checksum to data buffer
     *
     *  Parameters:
     *      data_buffer - ethernet frame data buffer with payload data
     *      dst_mac_address - destination MAC address
     *      src_mac_address - source MAC address
     *      frame_type - ethernet frame type
     *
     */
    function ethernet_frame_create(inout octet_t data_buffer[$], input mac_address_t dst_mac_address, input mac_address_t src_mac_address, input frame_type_t frame_type);
        ethernet_frame_header_t frame_header;
        octet_t[ETHERNET_FRAME_HEADER_SIZE - 1 : 0] header;
        octet_t[3 : 0] fcs;

        // Assigning the Required Values to the Packing Structure
        frame_header.preamble = { ETHERNET_PREAMBLE_OCTETS{ ETHERNET_PREAMBLE } };
        frame_header.sfd = ETHERNET_SFD;
        { <<octet_t{ frame_header.dst_mac_address } } = dst_mac_address;    // Reversing byte ordering
        { <<octet_t{ frame_header.src_mac_address } } = src_mac_address;    // Reversing byte ordering
        { <<octet_t{ frame_header.frame_type } } = frame_type;              // Reversing byte ordering

        $display("Create ethernet frame:");
        $write("\tDst MAC address: ");
        print_mac_address(dst_mac_address);
        $write("\tSrc MAC address: ");
        print_mac_address(src_mac_address);
        $display("\tFrame type: %04X", frame_type);

        // Reassigning values from a packed structure to a packed array
        header = frame_header;

        // Check payload size
        if (data_buffer.size() < ETHERNET_FRAME_MIN_PAYLOAD_SIZE) begin
            repeat (ETHERNET_FRAME_MIN_PAYLOAD_SIZE - data_buffer.size()) begin
                data_buffer.push_back(8'h00);
            end
        end

        // Filling the buffer with data
        foreach (header[i]) begin
            data_buffer.push_front(header[i]);
        end

        // Calculate checksum
        { <<octet_t{ fcs } } = ethernet_fcs(data_buffer[ETHERNET_PREAMBLE_OCTETS + 1 : data_buffer.size()]);
        foreach (fcs[i]) begin
            data_buffer.push_back(fcs[i]);
        end

    endfunction


    /**
     *  function - "arp_request_create"
     *  Create ARP request
     *
     *  Parameters:
     *      data_buffer - data buffer
     *      src_mac_address - source MAC address
     *      src_ip_address - source IP address
     *      dst_ip_address - destination IP address
     *
     */
    function arp_request_create(inout octet_t data_buffer[$], input mac_address_t src_mac_address, input ip_address_t src_ip_address, input ip_address_t dst_ip_address);
        ethernet_arp_packet_t arp_packet;
        octet_t[ETHERNET_ARP_PACKET_SIZE - 1 : 0] packet;

        { <<octet_t{ arp_packet.h_type } } = ETHERNET_LINK_PROTOCOL_TYPE;
        { <<octet_t{ arp_packet.p_type } } = ETHERNET_TYPE_IP4;
        arp_packet.h_len = $bits(mac_address_t) / $bits(octet_t);
        arp_packet.p_len = $bits(ip_address_t) / $bits(octet_t);
        { <<octet_t{ arp_packet.operation } } = ARP_REQUEST;
        { <<octet_t{ arp_packet.src_mac_address } } = src_mac_address;
        { <<octet_t{ arp_packet.src_ip_address } } = src_ip_address;
        arp_packet.dst_mac_address = { $bits(mac_address_t){ 1'b0 } };
        { <<octet_t{ arp_packet.dst_ip_address } } = dst_ip_address;

        $display("Create ARP request:");
        $write("\tSrc MAC address: ");
        print_mac_address(src_mac_address);
        $write("\tSrc IP address: ");
        print_ip_address(src_ip_address);
        $write("\tDst IP address: ");
        print_ip_address(dst_ip_address);

        // Reassigning values from a packed structure to a packed array
        packet = arp_packet;

        // Filling the buffer with data
        foreach (packet[i]) begin
            data_buffer.push_front(packet[i]);
        end

    endfunction


    /**
     *  function - "ip_packet_header_checksum"
     *  Calculate IPv4 header checksum
     *
     *  Parameters:
     *      data_buffer - ethernet frame data buffer with payload data
     *      packet_id - packet ID (identification)
     *
     */
    function octet_t[1 : 0] ip_packet_header_checksum(input ethernet_ip4_packet_header_t frame_header);
        bit[ETHERNET_IP4_PACKET_HEADER_SIZE / 2 - 1 : 0][15 : 0] header;
        bit[31 : 0] summ;

        frame_header.header_checksum = 16'h0000;
        header = frame_header;

        foreach (header[i]) begin
            summ += header[i];
            summ[15 : 0] += summ[31 : 16];
            summ &= 16'hFFFF;
        end
        ip_packet_header_checksum = ~summ;
    endfunction


    /**
     *  function - "ip_packet_create"
     *  Create IPv4 packet - add ethernet ftame header && checksum to data buffer
     *
     *  Parameters:
     *      data_buffer - ethernet frame data buffer with payload data
     *      packet_id - packet ID (identification)
     *      protocol_id - IP protocol number
     *      src_ip_address - source IP address
     *      dst_ip_address - destination IP address
     *
     */
    function ip_packet_create(inout octet_t data_buffer[$], input octet_t[1 : 0] packet_id, input octet_t protocol_id, input ip_address_t src_ip_address, input ip_address_t dst_ip_address);
        ethernet_ip4_packet_header_t packet_header;
        octet_t[ETHERNET_IP4_PACKET_HEADER_SIZE - 1 : 0] header;

        // Reverse nibbles in octet
        { <<nibble_t{ packet_header.ihl, packet_header.version } } = { ETHERNET_IP_IHL, ETHERNET_IP_VERSION };
        packet_header.tos = ETHERNET_IP_TOS;
        { <<octet_t{ packet_header.length } } = data_buffer.size() + ETHERNET_IP4_PACKET_HEADER_SIZE;
        { <<octet_t{ packet_header.identification } } = packet_id;
        { <<octet_t{ packet_header.fragment_offset, packet_header.flags } } = bit_revers_16({ ETHERNET_IP_FRAGMENT_OFFSET, ETHERNET_IP_FLAGS });
        packet_header.ttl = ETHERNET_IP_TTL;
        packet_header.protocol = protocol_id;
        { <<octet_t{ packet_header.src_ip_address } } = src_ip_address;
        { <<octet_t{ packet_header.dst_ip_address } } = dst_ip_address;
        packet_header.header_checksum = ip_packet_header_checksum(packet_header);

        $display("Create IPv4 packet:");
        $display("\tProtocol ID: %02X", protocol_id);
        $write("\tSrc IP address: ");
        print_ip_address(src_ip_address);
        $write("\tDst IP address: ");
        print_ip_address(dst_ip_address);

        // Reassigning values from a packed structure to a packed array
        header = packet_header;

        // Filling the buffer with data
        foreach (header[i]) begin
            data_buffer.push_front(header[i]);
        end

    endfunction

endpackage


`endif // VERILOG_ETHERNET_PACK_SV_

