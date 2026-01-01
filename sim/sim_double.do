# Create work library
vlib work

# Compile the SystemVerilog files
vlog -sv sha256.sv
vlog -sv sha_double.sv
vlog -sv sha256_core_tb.sv

# Start simulation
vsim -novopt sha256_double_tb

# Set up the wave window
add wave -divider "Clock and Reset"
add wave sim:/sha256_double_tb/clk
add wave sim:/sha256_double_tb/rst_n

add wave -divider "Control"
add wave sim:/sha256_double_tb/start
add wave sim:/sha256_double_tb/busy
add wave sim:/sha256_double_tb/done

add wave -divider "Wrapper State"
add wave sim:/sha256_double_tb/dut/state
add wave -radix hex sim:/sha256_double_tb/dut/hash1

add wave -divider "Core Interface"
add wave sim:/sha256_double_tb/dut/core_start
add wave sim:/sha256_double_tb/dut/core_done
add wave sim:/sha256_double_tb/dut/core/state

add wave -divider "Input/Output"
add wave -radix hex sim:/sha256_double_tb/block_in
add wave -radix hex sim:/sha256_double_tb/hash_out
add wave -radix hex sim:/sha256_double_tb/expected_hash

# Configure the wave window
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left

# Run the simulation
run -all

# Zoom to fit
wave zoom full
