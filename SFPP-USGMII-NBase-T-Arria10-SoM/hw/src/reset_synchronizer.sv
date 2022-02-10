/**
 *  File:               reset_synchronizer.sv
 *  Modules:            reset_synchronizer
 *  Start design:       14.11.2019
 *  Last revision:      16.12.2021
 *  Source language:    SystemVerilog 3.1a IEEE 1364-2001
 *
 *  Reset syncronizer - turns asynchronous reset to synchronous
 *  Copyright (c) 2019 Vadim A. Lukinov Wartech LLC
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
 *      14.11.2019              Create first versions of modules: "reset_syncronizer" - (Vadim A. Lukinov)
 *      16.12.2021              Changed the name of the module to "reset_synchronizer" - (Vadim A. Lukinov)
 *
 */
`ifndef RESET_SYNCHRONIZER_SV_
`define RESET_SYNCHRONIZER_SV_


/**
 *  module - "reset_synchronizer"
 *  Reset syncronizer - turns asynchronous reset to synchronous
 *
 *  Parameters:
 *      p_delay_cycles - number of reset ticks
 *
 */
module reset_synchronizer
#(
    parameter p_delay_cycles = 8
)(
    input logic i_clock,
    input logic i_async_reset_n,
    output logic o_sync_reset_n
);
    /// - Internal parameters & constants ----------------------------------------------------------

    localparam DELAY_CYCLES = p_delay_cycles;

    /// - Internal logic ---------------------------------------------------------------------------

    logic clock;
    logic reset_n;

    logic[DELAY_CYCLES - 1 : 0] reset_syncronizer;
    logic sync_reset_n;

    /// - Logic description ------------------------------------------------------------------------

    always_comb clock = i_clock;
    always_comb reset_n = i_async_reset_n;

    always_ff @(posedge clock, negedge reset_n) begin
        if (!reset_n)
            reset_syncronizer <= 0;
        else begin
            reset_syncronizer <= { reset_syncronizer[DELAY_CYCLES - 2 : 0], 1'b1 };
        end
    end

    always_comb sync_reset_n = reset_syncronizer[DELAY_CYCLES - 1];

    /// - Outputs ----------------------------------------------------------------------------------

    always_comb o_sync_reset_n = sync_reset_n;

endmodule


`endif // RESET_SYNCHRONIZER_SV_

