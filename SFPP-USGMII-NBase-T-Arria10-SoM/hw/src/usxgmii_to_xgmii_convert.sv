/**
 *  File:               usxgmii_to_xgmii_convert.sv
 *  Modules:            usxgmii_to_xgmii_convert
 *  Start design:       10.02.2022
 *  Last revision:      10.02.2022
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  USXGMII to XGMII protocol converter
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
 *      10.02.2022              Create first versions of modules: "usxgmii_to_xgmii_convert" - (Vadim A. Lukinov)
 *
 */
`ifndef USXGMII_TO_XGMII_CONVERT_SV_
`define USXGMII_TO_XGMII_CONVERT_SV_


/**
 *  module - "usxgmii_to_xgmii_convert"
 *  USXGMII to XGMII protocol converter
 *
 */
module usxgmii_to_xgmii_convert
(
    input logic i_xgmii_clock,
    input logic i_xgmii_reset_n,
    input logic i_usxgmii_clock,

    input logic i_usxgmii_valid,
    input logic[3 : 0] i_usxgmii_control,
    input logic[31 : 0] i_usxgmii_data,

    output logic[7 : 0] o_xgmii_control,
    output logic[63 : 0] o_xgmii_data
);
    /// - Internal logic ---------------------------------------------------------------------------

    logic xgmii_clock;
    logic xgmii_reset;
    logic xgmii_reset_n;
    logic usxgmii_clock;

    logic usxgmii_valid;
    logic[3 : 0] usxgmii_control;
    logic[31 : 0] usxgmii_data;

    logic[7 : 0] xgmii_control;
    logic[63 : 0] xgmii_data;

    logic fifo_wrreq;
    logic fifo_rdreq;

    logic usxgmii_to_xgmii_control_fifo_wrfull;
    logic usxgmii_to_xgmii_control_fifo_wrreq;
    logic[3 : 0] usxgmii_to_xgmii_control_fifo_data;
    logic usxgmii_to_xgmii_control_fifo_rdempty;
    logic usxgmii_to_xgmii_control_fifo_rdreq;
    logic[7 : 0] usxgmii_to_xgmii_control_fifo_q;

    logic usxgmii_to_xgmii_data_fifo_wrfull;
    logic usxgmii_to_xgmii_data_fifo_wrreq;
    logic[31 : 0] usxgmii_to_xgmii_data_fifo_data;
    logic usxgmii_to_xgmii_data_fifo_rdempty;
    logic usxgmii_to_xgmii_data_fifo_rdreq;
    logic[63 : 0] usxgmii_to_xgmii_data_fifo_q;

    /// - Logic description ------------------------------------------------------------------------

    always_comb xgmii_clock = i_xgmii_clock;
    always_comb xgmii_reset = ~xgmii_reset_n;
    always_comb xgmii_reset_n = i_xgmii_reset_n;
    always_comb usxgmii_clock = i_usxgmii_clock;

    always_ff @(posedge usxgmii_clock) usxgmii_valid <= i_usxgmii_valid;
    always_ff @(posedge usxgmii_clock) usxgmii_control <= i_usxgmii_control;
    always_ff @(posedge usxgmii_clock) usxgmii_data <= i_usxgmii_data;

    always_comb fifo_wrreq = usxgmii_valid & ~usxgmii_to_xgmii_control_fifo_wrfull & ~usxgmii_to_xgmii_data_fifo_wrfull;
    always_comb fifo_rdreq = ~usxgmii_to_xgmii_control_fifo_rdempty & ~usxgmii_to_xgmii_data_fifo_rdempty;

    always_comb usxgmii_to_xgmii_control_fifo_wrreq = fifo_wrreq;
    always_comb usxgmii_to_xgmii_control_fifo_data = usxgmii_control;

    always_comb usxgmii_to_xgmii_data_fifo_wrreq = fifo_wrreq;
    always_comb usxgmii_to_xgmii_data_fifo_data = usxgmii_data;

    always_comb usxgmii_to_xgmii_control_fifo_rdreq = fifo_rdreq;
    always_comb usxgmii_to_xgmii_data_fifo_rdreq = fifo_rdreq;

    always_ff @(posedge xgmii_clock) xgmii_control <= usxgmii_to_xgmii_control_fifo_q;
    always_ff @(posedge xgmii_clock) xgmii_data <= usxgmii_to_xgmii_data_fifo_q;

    /// - External modules -------------------------------------------------------------------------

    usxgmii_to_xgmii_control_fifo usxgmii_to_xgmii_control_fifo_i (
        .aclr(xgmii_reset),

        .wrclk(usxgmii_clock),
        .wrfull(usxgmii_to_xgmii_control_fifo_wrfull),
        .wrreq(usxgmii_to_xgmii_control_fifo_wrreq),
        .data(usxgmii_to_xgmii_control_fifo_data),

        .rdclk(xgmii_clock),
        .rdempty(usxgmii_to_xgmii_control_fifo_rdempty),
        .rdreq(usxgmii_to_xgmii_control_fifo_rdreq),
        .q(usxgmii_to_xgmii_control_fifo_q)
    );

    usxgmii_to_xgmii_data_fifo usxgmii_to_xgmii_data_fifo_i (
        .aclr(xgmii_reset),

        .wrclk(usxgmii_clock),
        .wrfull(usxgmii_to_xgmii_data_fifo_wrfull),
        .wrreq(usxgmii_to_xgmii_data_fifo_wrreq),
        .data(usxgmii_to_xgmii_data_fifo_data),

        .rdclk(xgmii_clock),
        .rdempty(usxgmii_to_xgmii_data_fifo_rdempty),
        .rdreq(usxgmii_to_xgmii_data_fifo_rdreq),
        .q(usxgmii_to_xgmii_data_fifo_q)
    );

    /// - Outputs ----------------------------------------------------------------------------------

    always_comb o_xgmii_control = xgmii_control;
    always_comb o_xgmii_data = xgmii_data;

endmodule


`endif // USXGMII_TO_XGMII_CONVERT_SV_

