# Create work library
vlib work

# Compile the SystemVerilog files
vlog -sv sha256_core.sv
vlog -sv sha256_core_tb.sv

# Start simulation
vsim -novopt sha256_core_tb

# Set up the wave window
add wave -divider "Clock and Reset"
add wave sim:/sha256_core_tb/clk
add wave sim:/sha256_core_tb/rst_n

add wave -divider "Control"
add wave sim:/sha256_core_tb/start
add wave sim:/sha256_core_tb/busy
add wave sim:/sha256_core_tb/done
add wave sim:/sha256_core_tb/init_hash

add wave -divider "Test Progress"
add wave -radix unsigned sim:/sha256_core_tb/test_num
add wave -radix unsigned sim:/sha256_core_tb/errors

add wave -divider "State Machine"
add wave sim:/sha256_core_tb/dut/state
add wave -radix unsigned sim:/sha256_core_tb/dut/round_counter

add wave -divider "Working Variables (a-h)"
add wave -radix hex sim:/sha256_core_tb/dut/a
add wave -radix hex sim:/sha256_core_tb/dut/b
add wave -radix hex sim:/sha256_core_tb/dut/c
add wave -radix hex sim:/sha256_core_tb/dut/d
add wave -radix hex sim:/sha256_core_tb/dut/e
add wave -radix hex sim:/sha256_core_tb/dut/f
add wave -radix hex sim:/sha256_core_tb/dut/g
add wave -radix hex sim:/sha256_core_tb/dut/h

add wave -divider "Hash State (H0-H7)"
add wave -radix hex sim:/sha256_core_tb/dut/H0
add wave -radix hex sim:/sha256_core_tb/dut/H1
add wave -radix hex sim:/sha256_core_tb/dut/H2
add wave -radix hex sim:/sha256_core_tb/dut/H3
add wave -radix hex sim:/sha256_core_tb/dut/H4
add wave -radix hex sim:/sha256_core_tb/dut/H5
add wave -radix hex sim:/sha256_core_tb/dut/H6
add wave -radix hex sim:/sha256_core_tb/dut/H7

add wave -divider "Input/Output"
add wave -radix hex sim:/sha256_core_tb/block_in
add wave -radix hex sim:/sha256_core_tb/hash_in
add wave -radix hex sim:/sha256_core_tb/hash_out
add wave -radix hex sim:/sha256_core_tb/expected_hash

add wave -divider "Round Computation"
add wave -radix hex sim:/sha256_core_tb/dut/W_current
add wave -radix hex sim:/sha256_core_tb/dut/T1
add wave -radix hex sim:/sha256_core_tb/dut/T2

# Configure the wave window
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left

# Run the simulation
run -all

# Zoom to fit
wave zoom full
