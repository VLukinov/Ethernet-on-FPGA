/**
 *  File:               sgmii_1000base_t_cyclone_iv_gx_starter_kit.sv
 *  Modules:            sgmii_1000base_t_cyclone_iv_gx_starter_kit
 *  Start design:       24.05.2021
 *  Last revision:      24.05.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  SGMII 1000Base-T example of using the "verilog-ethernet" library on Cyclone IV GX starter-kit
 *  Intel Cyclone IV GX (EP4CGX15BF14C8) FPGA
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
 *      24.05.2021              Create first versions of modules: "sgmii_1000base_t_cyclone_iv_gx_starter_kit" - (Vadim A. Lukinov)
 *
 */
`ifndef SGMII_1000BASE_T_CYCLONE_IV_GX_STARTER_KIT_SV_
`define SGMII_1000BASE_T_CYCLONE_IV_GX_STARTER_KIT_SV_


/**
 *  module - "sgmii_1000base_t_cyclone_iv_gx_starter_kit"
 *  SGMII 1000Base-T example of using the "verilog-ethernet" library on Cyclone IV GX starter-kit Top module
 *
 */
module sgmii_1000base_t_cyclone_iv_gx_starter_kit
#(
    parameter FPGA_REFERENCE_CLOCK_FREQUENCY = 125000000,
    parameter FPGA_RESET_DELAY_US = 20000,
    parameter FPGA_RESET_DELAY_TICKS = (FPGA_REFERENCE_CLOCK_FREQUENCY / 1000000) * FPGA_RESET_DELAY_US
)(
    input logic i_ref_clock,

    output logic[3 : 0] o_led
);
    /// - Internal parameters & constants ----------------------------------------------------------



    /// - Internal logic ---------------------------------------------------------------------------

    logic ref_clock;

    logic[3 : 0] led;
    logic[3 : 0] led_n;

    /// - Logic description ------------------------------------------------------------------------

    always_comb ref_clock = i_ref_clock;

    always_comb led[0] = 1'b0;
    always_comb led[1] = 1'b0;
    always_comb led[2] = 1'b0;
    always_comb led[3] = 1'b0;
    always_comb led_n = ~led;

    /// - External modules -------------------------------------------------------------------------



    /// - Outputs ----------------------------------------------------------------------------------

    always_comb o_led = led_n;

endmodule


`endif // SGMII_1000BASE_T_CYCLONE_IV_GX_STARTER_KIT_SV_

