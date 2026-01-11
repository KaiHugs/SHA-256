K# Bitcoin Miner HDL

Hardware implementation of a Bitcoin miner in SystemVerilog. Not practical for actual mining (wayyy too slow), but shows how the algorithm works at the hardware level. I <3 HDL.

## What's Implemented

Three phases, all working:

1. SHA-256 core - iterative design, 1 round per clock cycle
2. Double SHA-256 interface - chains two hashes automatically
3. Mining controller - tries different nonces until it finds a valid hash

## Files

### Hardware (HDL)

```
sha256.sv              - SHA-256 core
sha256_core_tb.sv      - Tests for SHA-256 core
sha_double.sv          - Double SHA interface
bitcoin_miner.sv       - Full mining controller
bitcoin_miner_tb.sv    - Mining tests
sim_sha256.do          - Run Phase 1 tests
sim_double.do          - Run Phase 2 tests  
sim_miner.do           - Run Phase 3 tests
```

### Software (RISC-V)

```
code/
  miner.c              - Mining control software (C)
  start.S              - RISC-V startup assembly
  link.ld              - Linker script for memory layout
  build.sh             - Build script for software compilation
  sha_ref.py           - Python reference for checking results
```

## Running Tests

Phase 1 (SHA-256 only):

```bash
vsim -do sim_sha256.do
```

Phase 2 (Double hash):

```bash
vsim -do sim_double.do
```

Phase 3 (Full miner):

```bash
vsim -do sim_miner.do
```

Phase 3 takes a while since it's actually trying to mine. Genesis block test might timeout - that's expected at simulation speed.

## How It Works

**Phase 1:** SHA-256 core does 64 compression rounds, one per cycle. Takes about 70 cycles total per 512-bit block.

**Phase 2:** interface automatically does two SHA-256 operations back-to-back. Bitcoin uses this everywhere.

**Phase 3:** Mining controller takes an 80-byte header, tries nonces 0, 1, 2, 3... until it finds one where the double SHA-256 is less than the target. The 80 bytes don't fit in one SHA block, so it splits into two blocks and chains them.

## Performance

At 50 MHz: ~220 cycles per nonce, roughly 227,000 hashes/second.

Real Bitcoin ASICs: 100 TH/s. So this is about 440 million times slower.

## Design Choices

## Common Issues

Different computer I ran required instead through wsl (reason unknown) sudo apt-get install gcc-riscv64-linux-gnu

## What's Tested

Phase 1: NIST vectors (empty string, "abc", "hello"), double hash of "hello", genesis block

Phase 2: Same tests using the interface

Phase 3: Easy target (finds quickly), impossible target (exhausts correctly), genesis block attempt, performance measurement

**Phase 4: FPGA Synthesis**
Get it running on actual hardware. Need to make a top-level interface, synthesize in Quartus, meet timing, program an FPGA boards.

**Phase 5: RISC-V Software Integration**

The Bitcoin miner uses a hybrid HDL+C architecture. Before compiling in Quartus, you must build the C software that runs on the embedded PicoRV32 RISC-V CPU.

**Building the Software:**

1. Install the RISC-V GCC toolchain (only tested on linux):
   **Windows/Linux:**

```bash
# 1. Install the RISC-V GCC toolchain
# https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v12.2.0-1/xpack-riscv-none-elf-gcc-12.2.0-1-linux-x64.tar.gz

# 2. Setup (see first section in setup.md)
cd ~ && tar -xzf xpack-riscv-none-elf-gcc-*.tar.gz

# 3. Go to the software directory and build:
cd code/ && ./build.sh
```

**macOS:**

```bash
brew tap riscv/riscv && brew install riscv-tools
cd code/ && ./build.sh
```

3. This compiles `miner.c` (mining control logic) into `program.hex` - machine code that gets embedded into FPGA RAM during Quartus synthesis.

**How It Works:**

The C software controls the hardware accelerator via memory-mapped registers at `0x80000000`:

- Loading block headers
- Setting difficulty targets
- Starting mining operations
- Reading nonce results

Copy `program.hex` to your Quartus project folder before synthesis. This separation lets you update mining logic quickly without recompiling the entire hardware design.

**Memory Map:**

```
0x00000000 - 0x00003FFF : RAM (16KB) - Program & data
0x80000000 - 0x800000FF : Miner MMIO registers
```

**MMIO Registers:**

```
0x80000000 : Control (start, busy, found flags)
0x80000004 : Max nonce
0x80000008 : Nonce output
0x8000000C : Hash output (8 words)
0x80000030 : Target (8 words)
0x80000050 : Header (20 words)
```

## Next Stages (Not Done)

**Phase 6: Optimization**

**Phase 7: Advanced Features**
Looking to Implement with RISC-V architecture - might take a million years to implement.

## Notes

Bitcoin header is 80 bytes:

- Version (4 bytes)
- Previous hash (32 bytes)
- Merkle root (32 bytes)
- Timestamp (4 bytes)
- Difficulty bits (4 bytes)
- Nonce (4 bytes) //This changes

Nonce goes at bytes 76-79 in little-endian. The miner updates these bytes for each attempt.

SHA-256 works on 512-bit blocks, so 80 bytes = 640 bits needs two blocks. Block 0 is the first 64 bytes, block 1 is the last 16 bytes plus padding.

## Requirements

- ModelSim (for simulation)
- Python 3 if you want to run sha_ref.py (optional)
- Quartus/Lite (for FPGA synthesis)
- RISC-V GCC toolchain (gcc-riscv64-unknown-elf) for software compilation

## Future Research

Looking to create a general-purpose research platform for FPGA-based acceleration. The current RISC-V + SHA-256 architecture provides a research-orientated foundation for studying hardware/software design patterns.

Working Towards:

1. Templating the interface to support multiple algorithms (AES, RSA, and eventually ML inference) beyond SHA-256, to allow for comparative studies of different acceleration strategies
2. Developing as an open-source SmartNIC platform for in-network computing research, where the SHA-256 core is used as a reusable in-network hashing block.

## Credits

- PicoRV32 by Claire Wolf (YosysHQ)
- SHA-256 implementation based on FIPS 180-4
- Bitcoin protocol by Satoshi Nakamoto

## License

Educational/Research project. **©** Kai Hughes 2026.

