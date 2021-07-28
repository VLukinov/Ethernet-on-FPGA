# for enhancing USB BlasterII to be reliable, 25MHz
create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck 3 [get_ports altera_reserved_tdo]
set_false_path -from [get_ports altera_reserved_ntrst] -to *

create_clock -name {ref_clock}  -period 125.0MHz [get_ports {i_ref_clock}]
create_clock -name {xcvr_ref_clock} -period 644.53125MHz [get_ports {i_xcvr_ref_clock}]

set_false_path -from *reset_n -to *

set_false_path -from * -to [get_ports o_sfp_*]
set_false_path -from [get_ports i_sfp_*] -to *

# set the number of channels
set ch_number 1

set clk_xgmii "sfp_ethernet_phy_control_i|xgmii_pll_i|xcvr_fpll_a10_0|outclk0"

# for 125MHz AVMM clock
set period_mgmt "125 MHz"

# for 125 MHz - clock for 1G
set period_1g "125 MHz"

# for 644MHz - clock for 10G
set period_10g "644.53125 MHz"

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create input reference Clocks
#**************************************************************
create_clock -name {pll_ref_clk_1g}  -period $period_1g   [get_ports {i_ref_clock}]
create_clock -name {pll_ref_clk_10g} -period $period_10g  [get_ports {i_xcvr_ref_clock}]
create_clock -name {phy_mgmt_clk}    -period $period_mgmt [get_ports {i_ref_clock}]

derive_pll_clocks -create_base_clocks
derive_clock_uncertainty

#**************************************************************
# Set Clock path suffix and data-path registers for below commands
# user is div_clkout output, 156MHz for 10G mode, 125MHz when in 1G mode for GIGE_PCS
# pma is pma_clkout output, 258MHz for 1588 and LT, 125MHz when in 1G mode for GIGE_PCS
# clkout is the same as div_clkout for 10G, AN, and 1G modes, but is 322MHz when in LT mode.
#**************************************************************
set  clk_rx_pma    "g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_rx_deser.inst_twentynm_hssi_pma_rx_deser|clkdiv"
set  clkout_rx     "g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_rx_pld_pcs_interface.inst_twentynm_hssi_rx_pld_pcs_interface|pld_pcs_rx_clk_out"
set  clkin_rx      "g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_rx_pld_pcs_interface.inst_twentynm_hssi_rx_pld_pcs_interface|pld_rx_clk"
set  clk_tx_pma    "g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_tx_ser.inst_twentynm_hssi_pma_tx_ser|clk_divtx"
set  clkout_tx     "g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_tx_pld_pcs_interface.inst_twentynm_hssi_tx_pld_pcs_interface|pld_pcs_tx_clk_out"
set  clkin_tx      "g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_tx_pld_pcs_interface.inst_twentynm_hssi_tx_pld_pcs_interface|pld_tx_clk"
set  cout_reg_tx   "g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pma|gen_twentynm_hssi_pma_tx_cgb.inst_twentynm_hssi_pma_tx_cgb|cpulse_out_bus[0]"

# automatically set the native_phy instance depending upon the synthesis parameters
set reg_check    [get_keepers -nowarn *native_10g_644_ls_inst*]
set length       [get_collection_size $reg_check]
if {$length!=0}  { set native_ls_inst "CHANNEL|DATAPATH_10G.NATIVE_PHY_10G_644_LS.native_10g_644_ls_inst|native_10g_644_ls|native_10g_644_ls_inst|"
                   set native_ls_variant 1
} else           { set native_ls_variant 0 }

set reg_check    [get_keepers -nowarn *native_10g_322_ls_inst*]
set length       [get_collection_size $reg_check]
if {$length!=0}  { set native_ls_inst "CHANNEL|DATAPATH_10G.NATIVE_PHY_10G_322_LS.native_10g_322_ls_inst|native_10g_322_ls|native_10g_322_ls_inst|"
                   set native_ls_variant 1
} else           { set native_ls_variant 0 }

## hard prbs version
set reg_check    [get_keepers -nowarn *native_10ghp_644_ls_inst*]
set length       [get_collection_size $reg_check]
if {$length!=0}  { set native_ls_inst "CHANNEL|DATAPATH_10G.NATIVE_PHY_10GHP_644_LS.native_10ghp_644_ls_inst|native_10ghp_644_ls|native_10ghp_644_ls_inst|"
                   set native_ls_variant 1
} else           { set native_ls_variant 0 }

set reg_check    [get_keepers -nowarn *native_10ghp_322_ls_inst*]
set length       [get_collection_size $reg_check]
if {$length!=0}  { set native_ls_inst "CHANNEL|DATAPATH_10G.NATIVE_PHY_10GHP_322_LS.native_10ghp_322_ls_inst|native_10ghp_322_ls|native_10ghp_322_ls_inst|"
                   set native_ls_variant 1
} else           { set native_ls_variant 0 }

# create generated clocks for 1G mode as the pma clock will change rate with PCS reconfiguration
# the Gige frequency is 125MHz
post_message -type info "Creating generated clocks for Gige Mode"
set instance 0
for {set i 0} {$i < $ch_number} {incr i} {
    set ch "sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|"

    # create the 1G RX clock
    set clock_name  "rxclk_1g_ch$instance"
    set source_node "$ch$native_ls_inst$clk_rx_pma"
    set clock_node  "$ch$native_ls_inst$clkout_rx"
    create_generated_clock -name $clock_name -source [get_pins $source_node] -divide_by 66 -multiply_by 32 [get_pins $clock_node] -add

    # create the 1G TX clock
    set clock_name  "txclk_1g_ch$instance"
    set source_node "$ch$native_ls_inst$clk_tx_pma"
    set clock_node  "$ch$native_ls_inst$clkout_tx"
    create_generated_clock -name $clock_name -source [get_pins $source_node] -divide_by 66 -multiply_by 32 [get_pins $clock_node] -add

    # create the 10G (default) clocks which were not created by the IPSTA due to 1G clocks just created above.
    # This is needed for adding PDN clock uncertainty in the HSSI for 14.1a10s
    # there was warning they weren't created. Used warning message to determine master_clock and "report ignored constraints" in timequest
    set clock_name  "rxclk_10g_ch$instance"
    set source_node "$ch$native_ls_inst$clk_rx_pma"
    set clock_node  "$ch$native_ls_inst$clkout_rx"
    create_generated_clock -name $clock_name -source [get_pins $source_node] [get_pins $clock_node] -add

    set clock_name  "txclk_10g_ch$instance"
    set source_node "$ch$native_ls_inst$clk_tx_pma"
    set clock_node  "$ch$native_ls_inst$clkout_tx"
    create_generated_clock -name $clock_name -source [get_pins $source_node] [get_pins $clock_node] -add

    # core clock inputs to HSSI for PDN uncertainty
    set clk_pdnrx_name "${ch}rx_coreclkin"
    set clock_source   "$ch$native_ls_inst$clkout_rx"
    set master_src     "rxclk_10g_ch${instance}"
    set clock_node     "$ch$native_ls_inst$clkin_rx"

    # Remove clock if exists- so you do not see warning
    set clk_exists [get_collection_size [get_clocks $clk_pdnrx_name]]
    if {$clk_exists} { remove_clock $clk_pdnrx_name}
    create_generated_clock -name $clk_pdnrx_name -source [get_pins $clock_source] -master_clock $master_src [get_pins $clock_node] -add

    # create 1G coreclkin so you see P2C, C2P xfers for 1G
    # 1G-rx-coreclkin is created similar to rx_corelkin ->use rxclk_1g_ch as master instead of rxclk_10g_ch
    set clk_pdnrx_name "${ch}rx_coreclkin_1g"
    set master_src     "rxclk_1g_ch${instance}"
    create_generated_clock -name $clk_pdnrx_name -source [get_pins $clock_source] -master_clock $master_src [get_pins $clock_node]  -add

    set clk_pdntx_name "${ch}tx_coreclkin"
    set clock_source   "$ch$native_ls_inst$clkout_tx"
    set master_src     "txclk_10g_ch${instance}"

    # Remove clock if exists- so you do not see warning
    set clk_exists [get_collection_size [get_clocks $clk_pdntx_name]]
    if {$clk_exists} { remove_clock $clk_pdntx_name}
    set clock_node     "$ch$native_ls_inst$clkin_tx"
    create_generated_clock -name $clk_pdntx_name -source [get_pins $clock_source] -master_clock $master_src [get_pins $clock_node] -add

    # create 1G coreclkin so you see P2C, C2P xfers for 1G
    # 1G-tx-coreclkin is created similar to tx_corelkin ->use txclk_1g_ch as master instead of txclk_10g_ch
    set clk_pdntx_name "${ch}tx_coreclkin_1g"
    set clock_source   "$ch$native_ls_inst$clkout_tx"
    set master_src     "txclk_1g_ch${instance}"
    create_generated_clock -name $clk_pdntx_name -source [get_pins $clock_source] -master_clock $master_src [get_pins $clock_node] -add

    # get the next channel in the list
    incr instance
}

#**************************************************************
# Set Clock Groups
#**************************************************************
set_clock_groups -asynchronous -group [get_clocks phy_mgmt_clk]
set_clock_groups -exclusive -group [get_clocks *rx_coreclkin_1g] -group [get_clocks rxclk_10g_ch* ]
set_clock_groups -exclusive -group [get_clocks *tx_coreclkin_1g] -group [get_clocks txclk_10g_ch* ]
set_clock_groups -exclusive -group [get_clocks *rx_coreclkin_1g] -group [get_clocks rxclk_10g_ch0* ]
set_clock_groups -exclusive -group [get_clocks *rx_coreclkin_1g] -group [get_clocks *rx_pma_div_clk ]

#**************************************************************
# Set False Paths
#**************************************************************
post_message -type info "Creating false paths for Gige Mode"
# These are for the 10G clocks/logic to the Gige logic
set_false_path   -from [get_clocks {pll_ref_clk_10g}] -to [get_registers -nowarn {*kr_gige_pcs_top*}]
set_false_path   -from [get_clocks *$clk_xgmii ]      -to [get_registers -nowarn {*kr_gige_pcs_top*}]
set_false_path   -from [get_clocks rxclk_10g_ch* ]    -to [get_registers -nowarn {*kr_gige_pcs_top*}]
set_false_path   -from [get_clocks txclk_10g_ch* ]    -to [get_registers -nowarn {*|alt_em10g32unit:alt_em10g32unit_inst|alt_em10g32_rx_top:rx_path.rx_top_inst|alt_em10g32_rx_rs_layer:rs_layer|alt_em10g32_rx_rs_gmii_mii:i_rx_rs_gmii_mii|*}]


# new for the 14.1a10 PDN clocks
# to the tx clocks
set_false_path   -from [get_clocks rxclk_10g_ch* ]     -to [get_clocks txclk_1g_ch* ]
set_false_path   -from [get_clocks *rx_pma_div_clk ]   -to [get_clocks txclk_1g_ch* ]
set_false_path   -from [get_clocks txclk_10g_ch* ]     -to [get_clocks txclk_1g_ch* ]
set_false_path   -from [get_clocks rxclk_1g_ch* ]      -to [get_clocks txclk_10g_ch* ]
set_false_path   -from [get_clocks rxclk_10g_ch* ]     -to [get_clocks txclk_10g_ch* ]
set_false_path   -from [get_clocks *rx_pma_div_clk ]   -to [get_clocks txclk_10g_ch* ]
set_false_path   -from [get_clocks txclk_1g_ch* ]      -to [get_clocks txclk_10g_ch* ]
set_false_path   -from [get_clocks txclk_1g_ch* ]      -to [get_clocks *tx_coreclkin ]

# to the rx clocks
set_false_path   -from [get_clocks txclk_10g_ch* ]     -to [get_clocks rxclk_1g_ch* ]
set_false_path   -from [get_clocks rxclk_10g_ch* ]     -to [get_clocks rxclk_1g_ch* ]
set_false_path   -from [get_clocks *rx_coreclkin ]     -to [get_clocks rxclk_1g_ch* ]
set_false_path   -from [get_clocks *rx_pma_clk ]       -to [get_clocks rxclk_1g_ch* ]
set_false_path   -from [get_clocks *rx_pma_div_clk ]   -to [get_clocks rxclk_1g_ch* ]
set_false_path   -from [get_clocks txclk_10g_ch* ]     -to [get_clocks rxclk_10g_ch* ]
set_false_path   -from [get_clocks txclk_1g_ch* ]      -to [get_clocks rxclk_10g_ch* ]
set_false_path   -from [get_clocks rxclk_1g_ch* ]      -to [get_clocks rxclk_10g_ch* ]
set_false_path   -from [get_clocks *rx_pma_div_clk ]   -to [get_clocks rxclk_10g_ch* ]
set_false_path   -from [get_clocks rxclk_10g_ch* ]     -to [get_clocks *rx_pma_div_clk ]
set_false_path   -from [get_clocks rxclk_1g_ch* ]      -to [get_clocks *rx_pma_div_clk ]
set_false_path   -from [get_clocks *rx_coreclkin ]     -to [get_clocks *rx_pma_div_clk ]

# these are for the Gige logic to the 10G logic
set_false_path -from [get_registers -nowarn {*kr_gige_pcs_top*}] -to  [get_clocks {pll_ref_clk_10g}]
# only tx-data[8:0] are real paths in GIGE mode. Rest higher bits, and 10G control signals false path for 1G clock
set_false_path -from {*sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|CHANNEL|rx_10g_control_inter*} -to txclk_1g_ch*

set_false_path -from [get_registers -nowarn {*kr_gige_pcs_top*}] -to  [get_clocks *$clk_xgmii]

#**************************************************************
# Set extra delay for core clock muxing in the IP
# this is to fix hold violations
#**************************************************************
if {$::quartus(nameofexecutable) == "quartus_fit"} {
    set_clock_uncertainty -hold -enable_same_physical_edge -from [get_clocks $clk_xgmii ] -to [get_clocks $clk_xgmii ] -add  0.100 }

if {$::quartus(nameofexecutable) == "quartus_fit"} {
    set_clock_uncertainty -hold -enable_same_physical_edge -from [get_clocks *rx_pma_div_clk ] -to [get_clocks *rx_pma_div_clk ] -add 0.100 }

# Any transition between XGMII-clk (156.25MHz) to TX/RX-clkout (257MHz) are technically false paths
# pld interface suppose to be time to XGMII-clk, somehow TX/RX-clkout get propagated
set_false_path -from [get_clocks rxclk_10g_ch*] -to *
set_false_path -from [get_clocks rxclk_1g_ch*]  -to *
set_false_path -from [get_clocks rxclk_10g_ch*] -to *
set_false_path -from [get_clocks rxclk_1g_ch*]  -to *

set_false_path -from * -to [get_clocks rxclk_10g_ch*]
set_false_path -from * -to [get_clocks rxclk_1g_ch*]
set_false_path -from * -to [get_clocks rxclk_10g_ch*]
set_false_path -from * -to [get_clocks rxclk_1g_ch*]

set_false_path -from [get_clocks *$clk_xgmii] -to {sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|CHANNEL|DATAPATH_10G.NATIVE_PHY_10G_644_LS.native_10g_644_ls_inst|*|native_10g_644_ls_inst|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_8g_tx_pcs.inst_twentynm_hssi_8g_tx_pcs~pld_tx_data_8g_fifo.reg}

## xgmii output should not be go to 125Mhz or 257mhz
set_false_path -from * -to [get_clocks txclk_1g_ch*]
set_false_path -from * -to [get_clocks txclk_10g_ch*]
set_false_path -from * -to [get_clocks txclk_1g_ch*]
set_false_path -from * -to [get_clocks txclk_10g_ch*]

set_false_path -from [get_clocks txclk_1g_ch*] -to *
set_false_path -from [get_clocks txclk_10g_ch*] -to *
set_false_path -from [get_clocks txclk_1g_ch*] -to *
set_false_path -from [get_clocks txclk_10g_ch*] -to *


## based on file altera_xcvr_10gkr_a10.sv, set_false_path -to [get_registers {*gf_clock_mux*ena_r0*}]
set_false_path -from * -to {sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|CHANNEL|RX_CLK_MUX_LS.gf_rx_clk_mux_inst|ena_r0[*]}
set_false_path -from * -to {sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|CHANNEL|TX_CLK_MUX_KR.gf_tx_clk_mux_inst|ena_r0[*]}

# Any transfer between output of FIFO and input of pipeline flop (tx_parallel_data_to_pcs) is only valid on 257MHz clock
set_false_path -from {sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|CHANNEL|DATAPATH_10G.NATIVE_PHY_10G_644_LS.native_10g_644_ls_inst|*|native_10g_644_ls_inst|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_rx_pld_pcs_interface.inst_twentynm_hssi_rx_pld_pcs_interface~pld_rx_control_fifo.reg} -to [get_clocks *$clk_xgmii]
set_false_path -from {sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|CHANNEL|DATAPATH_10G.NATIVE_PHY_10G_644_LS.native_10g_644_ls_inst|*|native_10g_644_ls_inst|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_rx_pld_pcs_interface.inst_twentynm_hssi_rx_pld_pcs_interface~pld_rx_data_fifo.reg} -to [get_clocks *$clk_xgmii]

# Any transition between XGMII-clk (156.25MHz) to TX/RX-clkout (257MHz) are technically false paths
set_false_path -from [get_clocks *$clk_xgmii] -to {sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|CHANNEL|DATAPATH_10G.NATIVE_PHY_10G_644_LS.native_10g_644_ls_inst|*|native_10g_644_ls_inst|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_10g_tx_pcs.inst_twentynm_hssi_10g_tx_pcs~pld_tx_data_10g_fifo.reg}
set_false_path -from [get_clocks *$clk_xgmii] -to {sfp_ethernet_phy_control_i|ethernet_phy_i|xcvr_10gkr_a10_0|CHANNEL|DATAPATH_10G.NATIVE_PHY_10G_644_LS.native_10g_644_ls_inst|*|native_10g_644_ls_inst|g_xcvr_native_insts[0].twentynm_xcvr_native_inst|twentynm_xcvr_native_inst|inst_twentynm_pcs|gen_twentynm_hssi_tx_pld_pcs_interface.inst_twentynm_hssi_tx_pld_pcs_interface~pld_tx_control_fifo.reg}


