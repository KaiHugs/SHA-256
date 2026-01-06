#!/bin/bash

# Bitcoin Miner Software Build Script
# Usage: ./build.sh [clean]

set -e  # Exit on error

# Configuration
ARCH="rv32i"
ABI="ilp32"
CC="riscv32-unknown-elf-gcc"
OBJCOPY="riscv32-unknown-elf-objcopy"
OBJDUMP="riscv32-unknown-elf-objdump"
SIZE="riscv32-unknown-elf-size"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Bitcoin Miner Software Build${NC}"
echo "================================"

# Clean if requested
if [ "$1" == "clean" ]; then
    echo "Cleaning..."
    rm -f *.o *.elf *.hex *.dis
    echo -e "${GREEN}Clean complete${NC}"
    exit 0
fi

# Check for toolchain
if ! command -v $CC &> /dev/null; then
    echo -e "${RED}Error: RISC-V toolchain not found${NC}"
    echo "Please install riscv32-unknown-elf-gcc"
    echo "See README.md for instructions"
    exit 1
fi

# Compile startup code
echo -e "${YELLOW}Compiling startup code...${NC}"
$CC -march=$ARCH -mabi=$ABI -c start.S -o start.o
echo "✓ start.o"

# Compile string utilities
echo -e "${YELLOW}Compiling string utilities...${NC}"
$CC -march=$ARCH -mabi=$ABI -O2 -c string_utils.c -o string_utils.o
echo "✓ string_utils.o"

# Compile main code
echo -e "${YELLOW}Compiling miner.c...${NC}"
$CC -march=$ARCH -mabi=$ABI -O2 -c miner.c -o miner.o
echo "✓ miner.o"

# Link
echo -e "${YELLOW}Linking...${NC}"
$CC -march=$ARCH -mabi=$ABI -nostdlib -T link.ld \
    start.o string_utils.o miner.o -o miner.elf
echo "✓ miner.elf"

# Generate hex file
echo -e "${YELLOW}Generating hex file...${NC}"
$OBJCOPY -O verilog miner.elf program.hex
echo "✓ program.hex"

# Generate disassembly for debugging
echo -e "${YELLOW}Generating disassembly...${NC}"
$OBJDUMP -d miner.elf > miner.dis
echo "✓ miner.dis"

# Show memory usage
echo ""
echo -e "${YELLOW}Memory Usage:${NC}"
$SIZE miner.elf

# Verify hex file
LINES=$(wc -l < program.hex)
echo ""
echo -e "${YELLOW}Hex File Stats:${NC}"
echo "Lines: $LINES"

# Show first few lines of hex file
echo ""
echo -e "${YELLOW}First 10 lines of program.hex:${NC}"
head -10 program.hex

echo ""
echo -e "${GREEN}Build complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Copy program.hex to your Quartus project directory"
echo "2. Compile in Quartus"
echo "3. Program the FPGA"
echo ""
echo "To clean: ./build.sh clean"