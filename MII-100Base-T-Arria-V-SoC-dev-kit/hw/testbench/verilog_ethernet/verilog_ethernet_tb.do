###
# ModelSim do file for "verilog_ethernet" module
#

set prj_name "verilog_ethernet"
set prj_name_tb ${prj_name}_tb

# Delete old compilation results
if [file exist work] {
    vdel -all
}

# Create new modelsim working library
vlib work

# Compile Altera Mega-Function library
if ![file exist altera_mf] {
    vlog -work altera_mf $::env(QUARTUS_ROOTDIR)/eda/sim_lib/altera_mf.v -createlib
}

# Compile all the Verilog sources in current folder into working library
vlog ./$prj_name_tb.sv
vlog ../../src/mii_100base_t_arria_v_soc_dev_kit.sv
vlog ../../src/fpga_core.v

vlog ../../../../verilog-ethernet/rtl/eth_mac_mii_fifo.v
vlog ../../../../verilog-ethernet/rtl/eth_axis_rx.v
vlog ../../../../verilog-ethernet/rtl/eth_axis_tx.v
vlog ../../../../verilog-ethernet/rtl/udp_complete.v
vlog ../../../../verilog-ethernet/rtl/ip_complete.v
vlog ../../../../verilog-ethernet/rtl/eth_mac_mii.v
vlog ../../../../verilog-ethernet/rtl/eth_mac_1g.v
vlog ../../../../verilog-ethernet/rtl/mii_phy_if.v
vlog ../../../../verilog-ethernet/rtl/axis_gmii_rx.v
vlog ../../../../verilog-ethernet/rtl/ssio_sdr_in.v
vlog ../../../../verilog-ethernet/rtl/lfsr.v
vlog ../../../../verilog-ethernet/rtl/axis_gmii_tx.v
vlog ../../../../verilog-ethernet/rtl/ip_arb_mux.v
vlog ../../../../verilog-ethernet/rtl/eth_arb_mux.v
vlog ../../../../verilog-ethernet/rtl/ip.v
vlog ../../../../verilog-ethernet/rtl/arp.v
vlog ../../../../verilog-ethernet/rtl/udp.v
vlog ../../../../verilog-ethernet/rtl/ip_eth_rx.v
vlog ../../../../verilog-ethernet/rtl/ip_eth_tx.v
vlog ../../../../verilog-ethernet/rtl/arp_eth_rx.v
vlog ../../../../verilog-ethernet/rtl/arp_eth_tx.v
vlog ../../../../verilog-ethernet/rtl/arp_cache.v
vlog ../../../../verilog-ethernet/rtl/udp_ip_rx.v
vlog ../../../../verilog-ethernet/rtl/udp_ip_tx.v
vlog ../../../../verilog-ethernet/rtl/udp_checksum_gen.v

vlog ../../../../verilog-ethernet/lib/axis/rtl/axis_fifo.v
vlog ../../../../verilog-ethernet/lib/axis/rtl/axis_async_fifo_adapter.v
vlog ../../../../verilog-ethernet/lib/axis/rtl/axis_async_fifo.v
vlog ../../../../verilog-ethernet/lib/axis/rtl/arbiter.v
vlog ../../../../verilog-ethernet/lib/axis/rtl/priority_encoder.v

# Open testbench module for simulation
vsim -novopt work.$prj_name_tb -L altera_mf

# Add all testbench signals to waveform diagram
# view wave -new -title $prj_name_tb
# add wave -window $prj_name_tb sim:/$prj_name_tb/*

view wave -new -title mii_100base_t_arria_v_soc_dev_kit
add wave -window mii_100base_t_arria_v_soc_dev_kit sim:/mii_100base_t_arria_v_soc_dev_kit_i/*

view wave -new -title fpga_core
add wave -window fpga_core sim:/mii_100base_t_arria_v_soc_dev_kit_i/fpga_core_i/*

# run -all
run 10ms
# wave zoom full

