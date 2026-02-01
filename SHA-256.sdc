# ==============================================================================
# Timing Constraints for Bitcoin Miner FPGA Design
# Author: Kai Hughes | 2025
# ==============================================================================

# Timing Constraints for Bitcoin Miner on DE2-115
# Save as: bitcoin_miner_de2115.sdc

# Create base clock from 50 MHz oscillator
create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]

# Derive PLL clocks (100 MHz system clock)
derive_pll_clocks -create_base_clocks

# Calculate clock uncertainty
derive_clock_uncertainty

# Set false paths for asynchronous inputs
set_false_path -from [get_ports KEY[*]] -to [all_clocks]
set_false_path -from [get_ports SW[*]] -to [all_clocks]

# Set false paths for LED outputs (no timing requirement)
set_false_path -from [all_clocks] -to [get_ports LEDR[*]]
set_false_path -from [all_clocks] -to [get_ports LEDG[*]]
set_false_path -from [all_clocks] -to [get_ports HEX*]

# SDRAM timing constraints
# Reference clock for SDRAM
set sdram_clk [get_clocks {pll|altpll_component|auto_generated|pll1|clk[0]}]

# SDRAM output delays
# Setup time: 1.5ns, Hold time: -0.8ns (typical values)
set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_ADDR[*]]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_ADDR[*]]

set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_BA[*]]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_BA[*]]

set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_CAS_N]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_CAS_N]

set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_RAS_N]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_RAS_N]

set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_WE_N]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_WE_N]

set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_CS_N]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_CS_N]

set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_DQM[*]]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_DQM[*]]

set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_CKE]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_CKE]

# SDRAM bidirectional data timing
# CAS latency = 3, so data valid after 3 clocks (~30ns at 100MHz)
# tAC (access time) = 5.4ns max
set_input_delay -clock $sdram_clk -max 5.4 [get_ports DRAM_DQ[*]]
set_input_delay -clock $sdram_clk -min 2.5 [get_ports DRAM_DQ[*]]

set_output_delay -clock $sdram_clk -max 1.5 [get_ports DRAM_DQ[*]]
set_output_delay -clock $sdram_clk -min -0.8 [get_ports DRAM_DQ[*]]

# Multicycle paths for SDRAM operations
# Read operations take 3 cycles (CAS latency)
set_multicycle_path -from $sdram_clk -to [get_ports DRAM_DQ[*]] -setup 2
set_multicycle_path -from $sdram_clk -to [get_ports DRAM_DQ[*]] -hold 1

# Cut timing paths between unrelated clock domains (if any)
# set_clock_groups -asynchronous -group {CLOCK_50} -group {$sdram_clk}

# Maximum delay for combinational logic
set_max_delay -from [all_inputs] -to [all_outputs] 20.0

# Optimize for speed
set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE PERFORMANCE"
set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON
set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING ON
set_global_assignment -name ROUTER_TIMING_OPTIMIZATION_LEVEL MAXIMUM
