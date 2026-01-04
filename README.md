# Bitcoin Miner HDL Project

Hardware implementation of a Bitcoin miner in SystemVerilog. Not practical for actual mining (wayyy too slow), but shows how the algorithm works at the hardware level. I <3 HDL.

## What's Implemented

Three phases, all working:

1. SHA-256 core - iterative design, 1 round per clock cycle
2. Double SHA-256 interface - chains two hashes automatically  
3. Mining controller - tries different nonces until it finds a valid hash

## Files

```
sha256.sv              - SHA-256 core
sha256_core_tb.sv      - Tests for SHA-256 core
sha_double.sv          - Double SHA interface
bitcoin_miner.sv       - Full mining controller
bitcoin_miner_tb.sv    - Mining tests
sha_ref.py             - Python reference for checking results
sim_sha256.do          - Run Phase 1 tests
sim_double.do          - Run Phase 2 tests  
sim_miner.do           - Run Phase 3 tests
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

## What's Tested

Phase 1: NIST vectors (empty string, "abc", "hello"), double hash of "hello", genesis block

Phase 2: Same tests using the interface

Phase 3: Easy target (finds quickly), impossible target (exhausts correctly), genesis block attempt, performance measurement

## Next Stages (Not Done)

**Phase 4: FPGA Synthesis**
Get it running on actual hardware. Need to make a top-level interface, synthesize in Quartus, meet timing, program an FPGA boards.

**Phase 5: Optimization**  


**Phase 6: Advanced Features**
Looking to Implement with RISC-V architecture - might take a million years to implement. 


## Notes

Bitcoin header is 80 bytes:
- Version (4 bytes)
- Previous hash (32 bytes)
- Merkle root (32 bytes)
- Timestamp (4 bytes)
- Difficulty bits (4 bytes)
- Nonce (4 bytes) - this is what changes

Nonce goes at bytes 76-79 in little-endian. The miner updates these bytes for each attempt.

SHA-256 works on 512-bit blocks, so 80 bytes = 640 bits needs two blocks. Block 0 is the first 64 bytes, block 1 is the last 16 bytes plus padding.

## Requirements

- ModelSim 
- Python 3 if you want to run sha_ref.py (optional)
- Quartus/Lite


## Future Research

 Looking to create a general-purpose research platform for FPGA-based acceleration. The current RISC-V + SHA-256 architecture provides a research-orientated foundation for studying hardware/software design patterns. 
 
 Working Towards:
(1) Templating the accelerator interface to support multiple algorithms (AES, RSA, and eventually ML inference ) beyond SHA-256, enabling comparative studies of different acceleration strategies;
(2) Developing as an open-source SmartNIC platform for in-network computing research, where the SHA-256 core could perform DDoS detection, or cache key generation at line-rate;

## License

Educational project. Do whatever you want with it. 2026. 
