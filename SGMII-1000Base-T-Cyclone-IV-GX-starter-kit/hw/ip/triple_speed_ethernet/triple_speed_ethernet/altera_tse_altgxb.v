// (C) 2001-2017 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1ns/1ns

module altera_tse_altgxb 
#(
parameter DEVICE_FAMILY           = "ARRIAGX",    //  The device family the the core is targetted for.
parameter STARTING_CHANNEL_NUMBER = 0,
parameter ENABLE_ALT_RECONFIG     = 0,
parameter ENABLE_SGMII            = 1,             //  Use to determine rate match FIFO in ALTGX GIGE mode

parameter RECONFIG_TOGXB_WIDTH      = 4,              //  Port width for reconfig_togxb
parameter RECONFIG_FROMGXB_WIDTH    = 17              //  Port width for reconfig_fromgxb
)
(
   input   ref_clk,
   input   rx_analogreset_sqcnr,
   input   rx_digitalreset_sqcnr_rx_clk,
   input   sd_loopback,
   input   tx_kchar,
   input   [7:0]  tx_frame,
   input   tx_digitalreset_sqcnr_tx_clk,
   output  pll_locked,
   output  rx_freqlocked,
   output  rx_kchar,
   output  rx_pcs_clk,
   output  [7:0]  rx_frame,
   output  rx_disp_err,
   output  rx_char_err_gx,
   output  rx_patterndetect,
   output  rx_runlengthviolation,
   output  rx_syncstatus,
   output  tx_pcs_clk,
   output  rx_rmfifodatadeleted,
   output  rx_rmfifodatainserted,
   output  rx_runningdisp,

   output  gxb_pwrdn_in_to_pcs,
   output  reconfig_busy_to_pcs,
   input   pcs_pwrdn_out_from_pcs,

   // SERDES control signals
   output  rx_recovclkout,
   input   gxb_pwrdn_in,
   input   reconfig_clk,
   input   [RECONFIG_TOGXB_WIDTH - 1:0] reconfig_togxb,
   input   reconfig_busy,
   output  pcs_pwrdn_out,
   output  [RECONFIG_FROMGXB_WIDTH -1:0] reconfig_fromgxb,

   // Calibration block clock
   input   gxb_cal_blk_clk,

   // Serial signals
   output  txp,
   input   rxp
);

  wire   [3:0] reconfig_togxb_wire;
  wire   [16:0] reconfig_fromgxb_wire;

// We are not using these signals, but for the sake of building the conduit interface
// we take it in and send it to PCS
assign gxb_pwrdn_in_to_pcs = gxb_pwrdn_in;
assign reconfig_busy_to_pcs = reconfig_busy;
assign pcs_pwrdn_out = pcs_pwrdn_out_from_pcs;

// Let us handle the width different for reconfig_togxb and reconfig_fromgxb port
// due to different device.
generate if (RECONFIG_TOGXB_WIDTH > 4)
begin
   // Append zero to the upper bits if the reconfig_togxb width is less than 4
   assign reconfig_togxb_wire = { {{4-RECONFIG_TOGXB_WIDTH}{1'b0}}, reconfig_togxb};
end
else
begin
   assign reconfig_togxb_wire = reconfig_togxb;
end
endgenerate

assign reconfig_fromgxb = reconfig_fromgxb_wire [RECONFIG_FROMGXB_WIDTH -1:0];

// Altgxb in GIGE mode
// --------------------
altera_tse_gxb_gige_inst the_altera_tse_gxb_gige_inst
(
   .cal_blk_clk (gxb_cal_blk_clk),
   .gxb_powerdown (gxb_pwrdn_in),
   .pll_inclk (ref_clk),
   .reconfig_clk (reconfig_clk),
   .reconfig_togxb (reconfig_togxb_wire),   
   .rx_analogreset (rx_analogreset_sqcnr),
   .rx_cruclk (ref_clk),
   .rx_datain (rxp),
   .rx_digitalreset (rx_digitalreset_sqcnr_rx_clk),
   .rx_seriallpbken (sd_loopback),
   .tx_ctrlenable (tx_kchar),
   .tx_datain (tx_frame),
   .tx_digitalreset (tx_digitalreset_sqcnr_tx_clk),
   .pll_powerdown (gxb_pwrdn_in),
   .pll_locked (pll_locked),
   .rx_freqlocked (rx_freqlocked),
   .reconfig_fromgxb (reconfig_fromgxb_wire),   
   .rx_ctrldetect (rx_kchar),
   .rx_clkout (rx_pcs_clk),
   .rx_dataout (rx_frame),
   .rx_disperr (rx_disp_err),
   .rx_errdetect (rx_char_err_gx),
   .rx_patterndetect (rx_patterndetect),
   .rx_rlv (rx_runlengthviolation),
   .rx_syncstatus (rx_syncstatus),
   .tx_clkout (tx_pcs_clk),
   .tx_dataout (txp),
   .rx_recovclkout (rx_recovclkout),
   .rx_rmfifodatadeleted (rx_rmfifodatadeleted),
   .rx_rmfifodatainserted (rx_rmfifodatainserted),
   .rx_runningdisp (rx_runningdisp)
);
defparam
   the_altera_tse_gxb_gige_inst.ENABLE_ALT_RECONFIG = ENABLE_ALT_RECONFIG,
   the_altera_tse_gxb_gige_inst.STARTING_CHANNEL_NUMBER = STARTING_CHANNEL_NUMBER,
   the_altera_tse_gxb_gige_inst.DEVICE_FAMILY = DEVICE_FAMILY,
   the_altera_tse_gxb_gige_inst.ENABLE_SGMII = ENABLE_SGMII;

endmodule
