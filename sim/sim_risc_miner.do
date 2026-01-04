# ModelSim simulation script for RISC-V Bitcoin Miner
# Run with: vsim -do sim_risc_miner.do

# Create work library
vlib work

# Compile all source files
echo "Compiling source files..."
vlog -sv sha256.sv
vlog -sv bitcoin_miner.sv
vlog picorv32.v
vlog Clock_100_PLL.v
vlog -sv risc_miner_interface.sv
vlog -sv risc_miner_tb.sv

# Choose which test to run
echo ""
echo "=========================================="
echo "Available Tests:"
echo "1. Full System Test (tb_risc_miner_interface)"
echo "2. CPU Interface Test (tb_cpu_interface)"  
echo "3. RAM Loading Test (tb_ram_loading)"
echo "4. PLL Test (tb_pll)"
echo "5. Mining Stimulus Test (tb_mining_stimulus)"
echo "=========================================="
echo ""

# Test 1: Full system test
echo "Running Test 1: Full System Test..."
vsim -voptargs=+acc tb_risc_miner_interface

# Add waves
add wave -position end sim:/tb_risc_miner_interface/CLOCK_50
add wave -position end sim:/tb_risc_miner_interface/rst_n_raw
add wave -position end -radix hex sim:/tb_risc_miner_interface/leds
add wave -position end sim:/tb_risc_miner_interface/dut/pll_locked
add wave -position end sim:/tb_risc_miner_interface/dut/clk_100
add wave -position end sim:/tb_risc_miner_interface/dut/rst_n

# CPU signals
add wave -divider "CPU Bus"
add wave -position end -radix hex sim:/tb_risc_miner_interface/dut/mem_addr
add wave -position end -radix hex sim:/tb_risc_miner_interface/dut/mem_wdata
add wave -position end -radix hex sim:/tb_risc_miner_interface/dut/mem_rdata
add wave -position end sim:/tb_risc_miner_interface/dut/mem_valid
add wave -position end sim:/tb_risc_miner_interface/dut/mem_ready

# Miner signals
add wave -divider "Miner"
add wave -position end sim:/tb_risc_miner_interface/dut/miner_start
add wave -position end sim:/tb_risc_miner_interface/dut/miner_busy
add wave -position end sim:/tb_risc_miner_interface/dut/miner_found
add wave -position end sim:/tb_risc_miner_interface/dut/miner_exhausted
add wave -position end -radix hex sim:/tb_risc_miner_interface/dut/nonce_out
add wave -position end -radix hex sim:/tb_risc_miner_interface/dut/max_nonce_reg

# Run
run 100ms

echo "Test 1 complete. Check transcript and waveforms."
echo ""

# To run other tests, uncomment the sections below:

# # Test 2: CPU Interface
# vsim -voptargs=+acc tb_cpu_interface
# add wave -position end sim:/tb_cpu_interface/*
# run -all

# # Test 3: RAM Loading
# vsim -voptargs=+acc tb_ram_loading
# run -all

# # Test 4: PLL
# vsim -voptargs=+acc tb_pll
# add wave -position end sim:/tb_pll/*
# run 2us

# # Test 5: Mining Stimulus
# vsim -voptargs=+acc tb_mining_stimulus
# add wave -position end sim:/tb_mining_stimulus/CLOCK_50
# add wave -position end sim:/tb_mining_stimulus/rst_n_raw
# add wave -position end -radix hex sim:/tb_mining_stimulus/leds
# add wave -position end sim:/tb_mining_stimulus/miner_busy
# add wave -position end sim:/tb_mining_stimulus/miner_found
# add wave -position end -radix hex sim:/tb_mining_stimulus/nonce_out
# add wave -position end -radix hex sim:/tb_mining_stimulus/hash_out
# run 50ms
