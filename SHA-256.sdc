# Timing Constraints for Bitcoin Miner

# Input clock constraint - 50 MHz from board
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# PLL Generated Clock - 100 MHz (10ns period)
# The PLL creates a 100MHz clock from the 50MHz input
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty (jitter, skew)
derive_clock_uncertainty

# Set input/output delays relative to CLOCK_50
# These are conservative estimates for board I/O
set_input_delay -clock CLOCK_50 -max 2.0 [all_inputs]
set_input_delay -clock CLOCK_50 -min 0.5 [all_inputs]
set_output_delay -clock CLOCK_50 -max 2.0 [all_outputs]
set_output_delay -clock CLOCK_50 -min 0.5 [all_outputs]

# Don't apply delays to clock inputs
remove_input_delay -clock CLOCK_50 [get_ports {CLOCK_50}]

# Don't time the reset path as critically
set_false_path -from [get_ports {rst_n_raw}]
set_false_path -to [get_ports {leds[*]}]

# Multicycle paths for slow interfaces (if needed)
# set_multicycle_path -from [get_registers {*}] -to [get_registers {*}] -setup 2
# set_multicycle_path -from [get_registers {*}] -to [get_registers {*}] -hold 1
