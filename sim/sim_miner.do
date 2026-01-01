# Create work library
vlib work

# Compile all SystemVerilog files
vlog -sv sha256.sv
vlog -sv bitcoin_miner.sv
vlog -sv bitcoin_miner_tb.sv

# Start simulation
vsim -novopt bitcoin_miner_tb

# Set up the wave window
add wave -divider "Clock and Reset"
add wave sim:/bitcoin_miner_tb/clk
add wave sim:/bitcoin_miner_tb/rst_n

add wave -divider "Miner Control"
add wave sim:/bitcoin_miner_tb/start
add wave sim:/bitcoin_miner_tb/busy
add wave sim:/bitcoin_miner_tb/found
add wave sim:/bitcoin_miner_tb/exhausted

add wave -divider "Test Progress"
add wave -radix unsigned sim:/bitcoin_miner_tb/test_num
add wave -radix unsigned sim:/bitcoin_miner_tb/errors

add wave -divider "Miner State"
add wave sim:/bitcoin_miner_tb/dut/state
add wave -radix hex sim:/bitcoin_miner_tb/dut/nonce
add wave -radix unsigned sim:/bitcoin_miner_tb/dut/hash_stage

add wave -divider "Results"
add wave -radix hex sim:/bitcoin_miner_tb/nonce_out
add wave -radix hex sim:/bitcoin_miner_tb/hash_out
add wave -radix hex sim:/bitcoin_miner_tb/target

add wave -divider "SHA-256 Core"
add wave sim:/bitcoin_miner_tb/dut/hasher/state
add wave -radix unsigned sim:/bitcoin_miner_tb/dut/hasher/round_counter
add wave sim:/bitcoin_miner_tb/dut/hasher_start
add wave sim:/bitcoin_miner_tb/dut/hasher_done

# Configure the wave window
configure wave -namecolwidth 300
configure wave -valuecolwidth 120
configure wave -justifyvalue left

# Run the simulation
run -all

# Zoom to fit
wave zoom full
