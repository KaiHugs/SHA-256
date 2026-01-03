#!/usr/bin/env python3
"""
SHA-256 reference implementation creating test vectors

Python makes this easy so verification is less ambiguious.
For the hardware design, the software models can do it with 
far less lines of code. Regardless, this python script is 
only used as a reference for verification knowing this is 
useless on board. 
"""

import hashlib
import struct

def sha256(data):
    return hashlib.sha256(data).digest()

def double_sha256(data):
    """Bitcoin's double hash, hash it twice."""
    return sha256(sha256(data))

def hex_str(data):
    """Convert byte to hex string for display."""
    return data.hex()

def main():
    print("=" * 70)
    print("SHA-256 Test Vector Generator")
    print("=" * 70)
    
    #empty
    print("\nTest 1: Empty String")
    result = sha256(b"")
    print(f"Hash:  {hex_str(result)}")
    print(f"Verilog:  256'h{hex_str(result)}")
    
    #"abc"
    print("\nTest 2: Message 'abc'")
    result = sha256(b"abc")
    print(f"Hash:  {hex_str(result)}")
    print(f"Verilog:  256'h{hex_str(result)}")
    
    #"hello"
    print("\nTest 3: Message 'hello'")
    result = sha256(b"hello")
    print(f"Hash:     {hex_str(result)}")
    print(f"Verilog:  256'h{hex_str(result)}")
    
    #double SHA-256 of "hello"
    print("\nTest 4: Double SHA-256 of 'hello'")
    result = double_sha256(b"hello")
    print(f"Hash:  {hex_str(result)}")
    print(f"Verilog:  256'h{hex_str(result)}")
    
    print("\n" + "=" * 70)
    print("Bitcoin Genesis Block")
    print("=" * 70)
    
    #first ever bitcoin block mined
    #values are in little endian (as bitcoin is)
    genesis_header = bytes.fromhex(
        "01000000"  #version
        "0000000000000000000000000000000000000000000000000000000000000000"  
        "3ba3edfd7a7b12b27ac72c3e76768f617fc81bc3888a51323a9fb8aa4b1e5e4a"  #merkle root
        "29ab5f49"  #timestamp
        "ffff001d"  #difficulty bits
        "1dac2b7c"  #nonce
    )
    
    print(f"Header: {hex_str(genesis_header)}")
    print(f"Length: {len(genesis_header)} bytes")
    
    #computing hashign
    result = double_sha256(genesis_header)
    print(f"\nHash (big-endian):    {hex_str(result)}")
    
    result_reversed = result[::-1]
    print(f"Hash (little-endian): {hex_str(result_reversed)}")
    print("           (how Bitcoin displays it)")
    
    #leading zeros - verificaiton
    print(f"\nLeading zero bytes: {len(result) - len(result.lstrip(b'\\x00'))}")
    
    expected = "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
    if hex_str(result_reversed) == expected:
        print("Matches known genesis block hash")
    else:
        print("Doesn't match")
    
    print("\n" + "=" * 70)
    print("Difficulty Check")
    print("=" * 70)
    
    #encoding
    bits = struct.unpack('<I', genesis_header[72:76])[0]
    print(f"Bits field: 0x{bits:08x}")
    
    #decoding
    exponent = bits >> 24
    mantissa = bits & 0xFFFFFF
    target = mantissa * (2 ** (8 * (exponent - 3)))
    
    print(f"Target:     {target:064x}")
    print(f"Hash:       {int.from_bytes(result, 'big'):064x}")
    
    if int.from_bytes(result, 'big') < target:
        print("Hash is less than target (valid POW)")
    else:
        print("Hash exceeds target (would be invalid)")
    
    print("\n" + "=" * 70)
    print("Block Structure")
    print("=" * 70)
    
    print("80-byte header needs to be processed as:")
    print("  Block 0: First 64 bytes")
    print("  Block 1: Last 16 bytes + padding")
    print("  Then: Second SHA-256 on the result")
    print("\nTotal: 3 SHA-256 operations per mining attempt")
    
    print("\n" + "=" * 70)
    print("Mini Mining Example")
    print("=" * 70)
    print("Finding a hash with 1 leading zero byte...")
    print("(Easier than real Bitcoin difficulty)")
    
    #test header
    test_header = bytearray(80)
    test_header[0:4] = struct.pack('<I', 1)  #v1
    #rest is zeros
    
    #different nonces
    for nonce in range(1000000):
        test_header[76:80] = struct.pack('<I', nonce)
        result = double_sha256(bytes(test_header))
        
        if result[0] == 0: 
            print(f"Found nonce: {nonce}")
            print(f"Hash: {hex_str(result)}")
            break
        
        if nonce % 10000 == 0 and nonce > 0:
            print(f" Tried {nonce:,} nonces...")
    else:
        print("Didn't find one in 1M attempts")
    
    print("\n" + "=" * 70)
    print("Done! Check nums")
    print("=" * 70)

if __name__ == "__main__":
    main()