# ==============================================================================
# Timing Constraints for Bitcoin Miner FPGA Design
# Author: Kai Hughes | 2025
# ==============================================================================

# ==============================================================================
# Clock Definitions
# ==============================================================================

# Create base clock - 50MHz input from board oscillator
create_clock -period 20.000 -name CLOCK_50 [get_ports CLOCK_50]

# Derive PLL clocks automatically - this creates the 100MHz clock
derive_pll_clocks

# Alternative manual definition if derive_pll_clocks doesn't work:
# create_generated_clock -name clk_100 -source [get_ports CLOCK_50] \
#     -multiply_by 2 [get_pins {pll|altpll_component|auto_generated|pll1|clk[0]}]

# ==============================================================================
# Clock Groups and Relationships
# ==============================================================================

# Set async relationship between input clock and PLL output
# This prevents timing analysis across clock domains
set_clock_groups -asynchronous \
    -group {CLOCK_50} \
    -group [get_clocks {pll|altpll_component|auto_generated|*}]

# ==============================================================================
# Input Constraints
# ==============================================================================

# Reset input - asynchronous, set false path
set_false_path -from [get_ports rst_n_raw] -to [all_registers]
set_false_path -from [get_registers {*reset_counter*}] -to [all_registers]

# ==============================================================================
# Output Constraints
# ==============================================================================

# LED outputs - don't need tight timing
set_false_path -to [get_ports {leds[*]}]

# ==============================================================================
# Timing Exceptions
# ==============================================================================

# Allow additional clock uncertainty for PLL outputs
derive_clock_uncertainty

# ==============================================================================
# Additional Constraints for Performance
# ==============================================================================

# Set max delay for combinational paths if needed
# set_max_delay -from [all_registers] -to [all_registers] 10.0

# Multicycle paths (if any critical paths need relaxation)
# Example: If SHA-256 computation is multi-cycle
# set_multicycle_path -from [get_registers {*sha256*}] -to [get_registers {*sha256*}] -setup 2
# set_multicycle_path -from [get_registers {*sha256*}] -to [get_registers {*sha256*}] -hold 1

# ==============================================================================
# Notes
# ==============================================================================
# - The PLL generates 100MHz from the 50MHz input
# - All internal logic runs at 100MHz
# - Reset is asynchronous and properly synchronized
# - LEDs don't need timing constraints as they're for display only
# ===============================