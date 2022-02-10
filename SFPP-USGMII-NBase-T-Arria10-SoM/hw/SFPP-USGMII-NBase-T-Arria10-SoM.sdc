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

