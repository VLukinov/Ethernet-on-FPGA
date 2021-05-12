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
    typedef octet_t[5 : 0] mac_address_t;
    typedef octet_t[1 : 0] frame_type_t;
    typedef octet_t[3 : 0] ip_address_t;

    localparam ETHERNET_FRAME_MIN_PAYLOAD_SIZE = 46;

    localparam ETHERNET_PREAMBLE_OCTETS = 7;
    const octet_t ETHERNET_PREAMBLE = 8'h55;                        // Ethernet frame preamble - 7 octets (0x55)
    const octet_t ETHERNET_SFD = 8'hD5;                             // Ethernet frame "Start frame delimiter" (SFD)

    const octet_t[1 : 0] ETHERNET_TYPE_IP4 = 16'h0800;              // Internet protocol v4
    const octet_t[1 : 0] ETHERNET_TYPE_ARP = 16'h0806;              // Address resolution protocol (ARP)
    const octet_t[1 : 0] ETHERNET_LINK_PROTOCOL_TYPE = 16'h0001;    // Ethernet link protocol type for ARP HTYPE

    // Ethernet frame header
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
     *  Create ethernet frame - add ethernet ftame header && checksum to data buffer
     *
     *  Parameters:
     *      data_buffer - ethrnrt frame data buffer with payload data
     *      dst_mac_address - destination MAC address
     *      src_mac_address - source MAC address
     *      frame_type - ethernet frame type
     *
     */
    function ethernet_frame_create(inout octet_t data_buffer[$], input mac_address_t dst_mac_address, input mac_address_t src_mac_address, input frame_type_t frame_type);
        ethernet_frame_header_t frame_header;
        octet_t[ETHERNET_FRAME_HEADER_SIZE - 1 : 0] header;
        octet_t[3 : 0] fcs;
        octet_t temp[];

        // Assigning the Required Values to the Packing Structure
        frame_header.preamble = { ETHERNET_PREAMBLE_OCTETS{ ETHERNET_PREAMBLE } };
        frame_header.sfd = ETHERNET_SFD;
        { <<octet_t{ frame_header.dst_mac_address } } = dst_mac_address;    // Reversing byte ordering
        { <<octet_t{ frame_header.src_mac_address } } = src_mac_address;    // Reversing byte ordering
        { <<octet_t{ frame_header.frame_type } } = frame_type;              // Reversing byte ordering

        $display("Create ethernet frane:");
        $write("\tDst MAC address:");
        { >>{ temp } } = frame_header.dst_mac_address;                      // Unpacking a packed array into an unpacked array
        print_buf(temp);
        $write("\tSrc MAC address:");
        { >>{ temp } } = frame_header.src_mac_address;                      // Unpacking a packed array into an unpacked array
        print_buf(temp);
        $write("\tFrame type:");
        { >>{ temp } } = frame_header.frame_type;                           // Unpacking a packed array into an unpacked array
        print_buf(temp);

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
        { >>{ temp } } = fcs;
        foreach (temp[i]) begin
            data_buffer.push_back(temp[i]);
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
        octet_t temp[];

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
        $write("\tSrc MAC address:");
        { >>{ temp } } = arp_packet.src_mac_address;                        // Unpacking a packed array into an unpacked array
        print_buf(temp);
        $write("\tSrc IP address:");
        { >>{ temp } } = arp_packet.src_ip_address;                         // Unpacking a packed array into an unpacked array
        print_buf(temp);
        $write("\tDst IP address:");
        { >>{ temp } } = arp_packet.dst_ip_address;                         // Unpacking a packed array into an unpacked array
        print_buf(temp);

        // Reassigning values from a packed structure to a packed array
        packet = arp_packet;

        // Filling the buffer with data
        foreach (packet[i]) begin
            data_buffer.push_front(packet[i]);
        end

    endfunction



endpackage


`endif // VERILOG_ETHERNET_PACK_SV_

