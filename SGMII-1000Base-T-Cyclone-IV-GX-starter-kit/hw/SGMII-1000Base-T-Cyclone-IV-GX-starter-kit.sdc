derive_pll_clocks -create_base_clocks
derive_clock_uncertainty

# 125MHz board input clock
create_clock -name {ref_clock} -period 125Mhz [get_ports {i_ref_clock}]

