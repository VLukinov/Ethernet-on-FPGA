/**
 *  File:               xgmii_to_usxgmii_convert.sv
 *  Modules:            xgmii_to_usxgmii_convert
 *  Start design:       10.02.2022
 *  Last revision:      10.02.2022
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  XGMII to USXGMII protocol converter
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
 *      10.02.2022              Create first versions of modules: "xgmii_to_usxgmii_convert" - (Vadim A. Lukinov)
 *
 */
`ifndef XGMII_TO_USXGMII_CONVERT_SV_
`define XGMII_TO_USXGMII_CONVERT_SV_


/**
 *  module - "xgmii_to_usxgmii_convert"
 *  XGMII to USXGMII protocol converter
 *
 */
module xgmii_to_usxgmii_convert
(
    input logic i_xgmii_clock,
    input logic i_xgmii_reset_n,
    input logic i_usxgmii_clock,

    input logic[7 : 0] i_xgmii_control,
    input logic[63 : 0] i_xgmii_data,

    output logic o_usxgmii_valid,
    output logic[3 : 0] o_usxgmii_control,
    output logic[31 : 0] o_usxgmii_data
);
    /// - Internal logic ---------------------------------------------------------------------------

    logic xgmii_clock;
    logic xgmii_reset;
    logic xgmii_reset_n;
    logic usxgmii_clock;

    logic usxgmii_valid;
    logic[3 : 0] usxgmii_control;
    logic[31 : 0] usxgmii_data;

    logic xgmii_valid;
    logic[7 : 0] xgmii_control;
    logic[63 : 0] xgmii_data;

    logic fifo_wrreq;
    logic fifo_rdreq;
    logic fifo_data_valid;

    logic xgmii_to_usxgmii_control_fifo_wrfull;
    logic xgmii_to_usxgmii_control_fifo_wrreq;
    logic[7 : 0] xgmii_to_usxgmii_control_fifo_data;
    logic xgmii_to_usxgmii_control_fifo_rdempty;
    logic xgmii_to_usxgmii_control_fifo_rdreq;
    logic[3 : 0] xgmii_to_usxgmii_control_fifo_q;

    logic xgmii_to_usxgmii_data_fifo_wrfull;
    logic xgmii_to_usxgmii_data_fifo_wrreq;
    logic[63 : 0] xgmii_to_usxgmii_data_fifo_data;
    logic xgmii_to_usxgmii_data_fifo_rdempty;
    logic xgmii_to_usxgmii_data_fifo_rdreq;
    logic[31 : 0] xgmii_to_usxgmii_data_fifo_q;

    /// - Logic description ------------------------------------------------------------------------

    always_comb xgmii_clock = i_xgmii_clock;
    always_comb xgmii_reset = ~xgmii_reset_n;
    always_comb xgmii_reset_n = i_xgmii_reset_n;
    always_comb usxgmii_clock = i_usxgmii_clock;

    always_ff @(posedge xgmii_clock) xgmii_valid <= xgmii_reset_n;
    always_ff @(posedge xgmii_clock) xgmii_control <= i_xgmii_control;
    always_ff @(posedge xgmii_clock) xgmii_data <= i_xgmii_data;

    always_comb fifo_wrreq = xgmii_valid & ~xgmii_to_usxgmii_control_fifo_wrfull & ~xgmii_to_usxgmii_data_fifo_wrfull;
    always_comb fifo_rdreq = ~xgmii_to_usxgmii_control_fifo_rdempty & ~xgmii_to_usxgmii_data_fifo_rdempty;
    always_ff @(posedge usxgmii_clock) fifo_data_valid <= fifo_rdreq;

    always_comb xgmii_to_usxgmii_control_fifo_wrreq = fifo_wrreq;
    always_comb xgmii_to_usxgmii_control_fifo_data = xgmii_control;

    always_comb xgmii_to_usxgmii_data_fifo_wrreq = fifo_wrreq;
    always_comb xgmii_to_usxgmii_data_fifo_data = xgmii_data;

    always_comb xgmii_to_usxgmii_control_fifo_rdreq = fifo_rdreq;
    always_comb xgmii_to_usxgmii_data_fifo_rdreq = fifo_rdreq;

    always_ff @(posedge usxgmii_clock) usxgmii_valid <= fifo_data_valid;
    always_ff @(posedge usxgmii_clock) usxgmii_control <= xgmii_to_usxgmii_control_fifo_q;
    always_ff @(posedge usxgmii_clock) usxgmii_data <= xgmii_to_usxgmii_data_fifo_q;

    /// - External modules -------------------------------------------------------------------------

    xgmii_to_usxgmii_control_fifo xgmii_to_usxgmii_control_fifo_i (
        .aclr(xgmii_reset),

        .wrclk(xgmii_clock),
        .wrfull(xgmii_to_usxgmii_control_fifo_wrfull),
        .wrreq(xgmii_to_usxgmii_control_fifo_wrreq),
        .data(xgmii_to_usxgmii_control_fifo_data),

        .rdclk(usxgmii_clock),
        .rdempty(xgmii_to_usxgmii_control_fifo_rdempty),
        .rdreq(xgmii_to_usxgmii_control_fifo_rdreq),
        .q(xgmii_to_usxgmii_control_fifo_q)
    );

    xgmii_to_usxgmii_data_fifo xgmii_to_usxgmii_data_fifo_i (
        .aclr(xgmii_reset),

        .wrclk(xgmii_clock),
        .wrfull(xgmii_to_usxgmii_data_fifo_wrfull),
        .wrreq(xgmii_to_usxgmii_data_fifo_wrreq),
        .data(xgmii_to_usxgmii_data_fifo_data),

        .rdclk(usxgmii_clock),
        .rdempty(xgmii_to_usxgmii_data_fifo_rdempty),
        .rdreq(xgmii_to_usxgmii_data_fifo_rdreq),
        .q(xgmii_to_usxgmii_data_fifo_q)
    );

    /// - Outputs ----------------------------------------------------------------------------------

    always_comb o_usxgmii_valid = usxgmii_valid;
    always_comb o_usxgmii_control = usxgmii_control;
    always_comb o_usxgmii_data = usxgmii_data;

endmodule



`endif // XGMII_TO_USXGMII_CONVERT_SV_

