derive_pll_clocks -create_base_clocks
derive_clock_uncertainty

# 125MHz board input clock
create_clock -name {ref_clock} -period 125Mhz [get_ports {i_ref_clock}]

# for enhancing USB BlasterII to be reliable, 25MHz
create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck 3 [get_ports altera_reserved_tdo]

set_false_path -from * -to [get_ports o_phy_reset_n]

